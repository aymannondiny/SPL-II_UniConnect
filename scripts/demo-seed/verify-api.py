#!/usr/bin/env python3
"""Optional local API acceptance checks. Creates/revokes login sessions; never prints tokens.

Run against a freshly seeded demo backend only. This is not a read-only database check:
login, context selection and logout write session rows, so run pristine SQL checks first.
"""
import argparse
import csv
import json
from decimal import Decimal
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler, ProxyHandler


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class DemoCheckError(Exception):
    pass


def require(condition, description):
    if not condition:
        raise DemoCheckError(description)
    print('PASS:', description)


class DemoApi:
    def __init__(self, base_url):
        self.base_url = base_url.rstrip('/')
        # Do not send demo passwords through a proxy or follow redirects off localhost.
        self.opener = build_opener(ProxyHandler({}), NoRedirect())
        self.sessions = {}

    def call(self, method, path, expected=200, token=None, body=None):
        headers = {'Accept': 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        data = None
        if body is not None:
            data = json.dumps(body).encode('utf-8')
            headers['Content-Type'] = 'application/json'
        request = Request(self.base_url + path, data=data, headers=headers, method=method)
        try:
            with self.opener.open(request, timeout=20) as response:
                code, raw = response.status, response.read()
        except HTTPError as error:
            code, raw = error.code, error.read()
        if code != expected:
            raise DemoCheckError(f'{method} {path}: expected HTTP {expected}, got {code}')
        return json.loads(raw) if raw else None

    def login(self, account):
        response = self.call('POST', '/api/v1/auth/login', body={
            'email': account['email'], 'password': 'LocalOnly!234'})
        token = response['accessToken']
        # Retain the token only in memory, never write it to a log/file.
        self.sessions[account['email']] = token
        return token

    def close(self):
        failures = 0
        for token in self.sessions.values():
            try:
                self.call('POST', '/api/v1/auth/logout', expected=204, token=token)
            except (DemoCheckError, URLError):
                failures += 1
        if failures:
            print(f'NOTE: {failures} demo session logout(s) failed; no token values printed.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-url', default='http://127.0.0.1:18084')
    args = parser.parse_args()
    url = urlsplit(args.base_url)
    if (url.scheme != 'http' or url.hostname not in ('127.0.0.1', 'localhost')
            or url.username or url.password or url.query or url.fragment
            or url.path not in ('', '/')):
        parser.error('Use an HTTP localhost demo-backend URL with no path or credentials.')
    api = DemoApi(args.base_url)
    accounts_path = Path(__file__).with_name('accounts.csv')
    with accounts_path.open(newline='', encoding='utf-8') as source:
        accounts = list(csv.DictReader(source))
    tokens = {}
    try:
        for account in accounts:
            if account['account_status'] == 'ACTIVE':
                token = api.login(account)
                me = api.call('GET', '/api/v1/auth/me', token=token)
                require(me['userId'] == int(account['user_id']), 'Login identity: ' + account['full_name'])
                tokens[int(account['user_id'])] = token
            else:
                api.call('POST', '/api/v1/auth/login', expected=401, body={
                    'email': account['email'], 'password': 'LocalOnly!234'})
                require(True, 'Login denied: ' + account['full_name'])

        creator = tokens[2]
        recommendations = api.call('GET', '/api/v1/projects/1/recommendations', token=creator)
        require([r['userId'] for r in recommendations] == [3, 4, 5], 'Recommendation order and exclusions')
        require([Decimal(str(r['score'])) for r in recommendations]
                == [Decimal('100'), Decimal('45'), Decimal('36.25')], 'Scores: 100.00 / 45.00 / 36.25')
        candidates = api.call('GET', '/api/v1/projects/candidates?requiredSkills=java&requiredSkills=sql&page=0&size=50', token=creator)
        require(3 in [x['userId'] for x in candidates['items']] and 7 not in [x['userId'] for x in candidates['items']], 'Required skill matching and hidden profile exclusion')

        connected = api.call('GET', '/api/v1/members/4', token=creator)
        private = api.call('GET', '/api/v1/members/7', token=creator)
        require(connected['detailsVisible'] and not private['detailsVisible'], 'Connected versus hidden profile details')
        require('email' not in private, 'Public member DTO omits email')

        mentee, outsider = tokens[12], tokens[18]
        visible = api.call('GET', '/api/v1/mentorship/slots/1', token=mentee)
        hidden = api.call('GET', '/api/v1/mentorship/slots/1', token=outsider)
        require(visible['meetingLink'] is not None and hidden['meetingLink'] is None, 'Mentorship meeting-link privacy')
        full = api.call('GET', '/api/v1/mentorship/slots/2', token=outsider)
        require(full['status'] == 'FULL' and full['vacancies'] == 0 and full['enrollmentOpen'], 'Derived FULL independent of enrollment closure')
        closed = api.call('GET', '/api/v1/mentorship/slots/3', token=outsider)
        require(closed['status'] == 'CLOSED' and not closed['enrollmentOpen'], 'Closed enrollment series')
        cancelled = api.call('GET', '/api/v1/mentorship/slots/4', token=mentee)
        require(cancelled['status'] == 'CANCELLED' and cancelled['nextOccurrenceStartsAt'] is None, 'Cancelled series has no next meeting')
        completed = api.call('GET', '/api/v1/mentorship/slots/5', token=tokens[11])
        require(completed['status'] == 'COMPLETED', 'Derived completed mentorship series')
        history = api.call('GET', '/api/v1/mentorship/slots/my-participation', token=mentee)
        require(any(e['enrollmentId'] == 1 and e['status'] == 'LEFT' and e['meetingLink'] is None for e in history), 'Historical LEFT period hides link after rejoin')
        api.call('GET', '/api/v1/mentorship/slots/1/enrollments', expected=403, token=outsider)
        require(True, 'Outsider cannot read mentor roster')
        for suffix in ('', '&topic=', '&topic=%20%20', '&topic=aLuMnI', '&topic=not-a-seeded-topic'):
            api.call('GET', '/api/v1/mentorship/slots?page=0&size=20' + suffix, token=outsider)
        require(True, 'PostgreSQL browse with omitted, blank and case-insensitive topics')

        reporter = tokens[17]
        for post_id in (2, 3):
            api.call('GET', f'/api/v1/career/posts/{post_id}', token=reporter)
            api.call('GET', f'/api/v1/career/posts/{post_id}', expected=404, token=outsider)
        require(True, 'Saved closed/expired career access; outsider denied')
        report = api.call('GET', '/api/v1/reports/1', token=reporter)
        require(report['status'] == 'ACTION_TAKEN' and not ({'targetSnapshot', 'internalNotes', 'action'} & report.keys()), 'Reporter sees outcome without administrative evidence')
        admin = tokens[1]
        api.call('PUT', '/api/v1/auth/contexts/active', token=admin, body={'contextType': 'SYSTEM_ADMINISTRATION'})
        queue = api.call('GET', '/api/v1/admin/reports?page=0&size=20', token=admin)
        require(queue['totalElements'] == 7, 'Administrator report queue')
        evidence = api.call('GET', '/api/v1/admin/reports/1', token=admin)
        require(evidence['action']['subjectId'] == 19, 'Owner-matched committed suspension evidence')
        api.call('GET', '/api/v1/admin/reports?page=0&size=20', expected=403, token=outsider)
        require(True, 'Ordinary account cannot read administrative reports')
        print('Demo API checks completed. No project/enrollment/report/content mutations submitted.')
    finally:
        api.close()


if __name__ == '__main__':
    try:
        main()
    except (DemoCheckError, URLError, KeyError, ValueError) as error:
        # Never print response bodies, Request objects or authorization values.
        print('FAIL:', str(error) if isinstance(error, DemoCheckError) else type(error).__name__)
        raise SystemExit(1)
