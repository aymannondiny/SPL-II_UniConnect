#!/usr/bin/env python3
"""Read-oriented presentation checks. It logs in and logs out, but consumes no pending action."""
import argparse
import json
from decimal import Decimal
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler, ProxyHandler


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class CheckError(Exception):
    pass


def require(value, label):
    if not value:
        raise CheckError(label)
    print('PASS:', label)


class Api:
    def __init__(self, base):
        self.base = base.rstrip('/')
        self.opener = build_opener(ProxyHandler({}), NoRedirect())
        self.tokens = []

    def call(self, method, path, token=None, body=None, expected=200):
        headers = {'Accept': 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        data = None
        if body is not None:
            data = json.dumps(body).encode()
            headers['Content-Type'] = 'application/json'
        try:
            with self.opener.open(Request(self.base + path, data=data, headers=headers, method=method), timeout=30) as response:
                status, raw = response.status, response.read()
        except HTTPError as error:
            status, raw = error.code, error.read()
        if status != expected:
            raise CheckError(f'{method} {path}: expected HTTP {expected}, got {status}')
        return json.loads(raw) if raw else None

    def login(self, email):
        result = self.call('POST', '/api/v1/auth/login', body={'email': email, 'password': 'Seed!234'})
        self.tokens.append(result['accessToken'])
        me = self.call('GET', '/api/v1/auth/me', token=result['accessToken'])
        require(me['email'].lower() == email, 'login identity ' + email)
        return result['accessToken']

    def close(self):
        for token in self.tokens:
            try:
                self.call('POST', '/api/v1/auth/logout', token=token, expected=204)
            except Exception:
                pass


def find(items, field, value):
    return next(item for item in items if item[field] == value)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url', required=True)
    args = parser.parse_args()
    parsed = urlsplit(args.base_url)
    if parsed.scheme not in ('http', 'https') or parsed.username or parsed.password or parsed.query or parsed.fragment or parsed.path not in ('', '/'):
        parser.error('base URL must be a credential-free HTTP(S) origin')
    api = Api(args.base_url)
    try:
        farhan = api.login('pres.farhan.rahman@iut-dhaka.edu')
        tasnim = api.login('pres.tasnim.ahmed@iut-dhaka.edu')
        arif = api.login('pres.arif.hossain@iut-dhaka.edu')
        sadia = api.login('pres.sadia.afrin@iut-dhaka.edu')
        zubair = api.login('pres.zubair.ahmed@iut-dhaka.edu')
        nabila = api.login('pres.nabila.sultana@iut-dhaka.edu')
        aisha = api.login('pres.aisha.siddika@iut-dhaka.edu')
        arif_reports = arif
        ahmed = api.login('pres.ahmed.faisal@iut-dhaka.edu')
        ayman = api.login('ayman@iut-dhaka.edu')
        sayma = api.login('sayma@iut-dhaka.edu')

        projects = api.call('GET', '/api/v1/projects?page=0&size=50', token=farhan)['items']
        anchor = find(projects, 'title', 'Campus Services API')
        recommendations = api.call('GET', f"/api/v1/projects/{anchor['id']}/recommendations", token=farhan)
        require([x['displayName'] for x in recommendations[:3]] == ['Abdullah Al Mamun', 'Tasnim Ahmed', 'Nusrat Jahan'],
                'calculated recommendation top three')
        require([Decimal(str(x['score'])) for x in recommendations[:3]] == [Decimal('86.97'), Decimal('48.79'), Decimal('44.85')],
                'calculated recommendation scores')

        careers = api.call('GET', '/api/v1/career/posts?page=0&size=50', token=arif)['items']
        require(any(x['title'] == 'Associate Product Intern' for x in careers), 'active career opportunity visible')
        saved = api.call('GET', '/api/v1/career/saved?page=0&size=50', token=arif)['items']
        require(any(x['post']['title'] == 'Associate Product Intern' for x in saved), 'saved career post visible')

        slots = api.call('GET', '/api/v1/mentorship/slots?page=0&size=50', token=tasnim)['items']
        backend = find(slots, 'topic', 'Backend Design Clinic')
        require(backend['meetingLink'] is not None, 'enrolled mentee sees meeting link')
        outsider_slots = api.call('GET', '/api/v1/mentorship/slots?page=0&size=50', token=arif)['items']
        require(find(outsider_slots, 'topic', 'Backend Design Clinic')['meetingLink'] is None, 'outsider meeting link hidden')
        require(find(slots, 'topic', 'Flutter Testing Workshop')['status'] == 'FULL', 'full mentorship derived state')

        clubs = api.call('GET', '/api/v1/clubs?page=0&size=50', token=sadia)['items']
        require(any(x['clubName'] == 'UniConnect Innovation Society' for x in clubs), 'presentation club visible')
        announcements = api.call('GET', '/api/v1/announcements?page=0&size=50', token=sadia)['items']
        require(any(x['title'] == 'Innovation Week volunteer briefing' for x in announcements), 'club announcement visible')
        events = api.call('GET', '/api/v1/events?page=0&size=50', token=sadia)['items']
        require(any(x['title'] == 'Innovation Week Showcase' for x in events), 'upcoming event visible')

        report_reasons = {
            'Presentation report for reviewing a fictional project description.',
            'Presentation review of a safely fictional closed opportunity.',
            'This appears to duplicate the earlier prototype registration promotion.',
            'This event repeats an internship briefing with conflicting registration details.',
            'The profile appears to repeat an unrelated project promotion.',
            'Several recent descriptions appear to repeat the same promotional wording.',
            'This follow-up appears off-topic for the volunteer-planning thread.',
            'The profile summary may overstate participation in a fictional campus activity.',
            'The club description looks similar to another career promotion.',
            'The completed event still appears to show outdated participation details.',
        }
        reports = api.call('GET', '/api/v1/reports?page=0&size=20', token=nabila)['items']
        nabila_action = find(reports, 'reason', 'This appears to duplicate the earlier prototype registration promotion.')
        require(nabila_action['status'] == 'ACTION_TAKEN' and nabila_action['resolutionSummary'],
                'reporter sees action-taken outcome and safe summary')
        require(not ({'targetSnapshot', 'internalNotes', 'reviewerId', 'action', 'history'} & set(nabila_action)),
                'reporter response excludes administrator-only evidence')
        arif_report_items = api.call('GET', '/api/v1/reports?page=0&size=20', token=arif_reports)['items']
        arif_action = find(arif_report_items, 'reason',
                           'This event repeats an internship briefing with conflicting registration details.')
        api.call('GET', f"/api/v1/reports/{arif_action['id']}", token=nabila, expected=404)
        require(True, 'reporter cannot read another reporter report')
        aisha_reports = api.call('GET', '/api/v1/reports?page=0&size=20', token=aisha)['items']
        aisha_outcome = find(aisha_reports, 'reason',
                             'The profile summary may overstate participation in a fictional campus activity.')
        require(aisha_outcome['status'] == 'NO_ACTION' and aisha_outcome['resolutionSummary'],
                'reporter sees dismissed outcome and safe summary')
        resolved_notifications = api.call('GET', '/api/v1/notifications?page=0&size=50', token=aisha)['items']
        require(any(x['type'] == 'REPORT_RESOLVED' and x['referenceId'] == aisha_outcome['id']
                    for x in resolved_notifications), 'report resolution notification visible')

        api.call('GET', '/api/v1/admin/reports?page=0&size=50', token=farhan, expected=403)
        require(True, 'regular account cannot access report administration')
        api.call('PUT', '/api/v1/auth/contexts/active', token=ayman, body={'contextType': 'SYSTEM_ADMINISTRATION'})
        queue = api.call('GET', '/api/v1/admin/reports?page=0&size=50', token=ayman)['items']
        presentation_queue = [x for x in queue if x['reason'] in report_reasons]
        require(len(presentation_queue) == 10, 'all ten presentation reports visible to administrator')
        require({x['targetType'] for x in presentation_queue} ==
                {'USER', 'CLUB', 'ANNOUNCEMENT', 'EVENT', 'CHAT_MESSAGE', 'PROJECT', 'CAREER_POST'},
                'administrator queue covers all seven supported target types')
        require({state: sum(x['status'] == state for x in presentation_queue) for state in
                 ('SUBMITTED', 'UNDER_REVIEW', 'ACTION_TAKEN', 'NO_ACTION')} ==
                {'SUBMITTED': 3, 'UNDER_REVIEW': 3, 'ACTION_TAKEN': 2, 'NO_ACTION': 2},
                'administrator queue has the intended lifecycle distribution')
        require(all(x['internalNotes'] is None for x in presentation_queue if x['status'] == 'UNDER_REVIEW'),
                'under-review fixtures match service note semantics')
        for state, expected_count in (('SUBMITTED', 3), ('UNDER_REVIEW', 3),
                                      ('ACTION_TAKEN', 2), ('NO_ACTION', 2)):
            filtered = api.call('GET', f'/api/v1/admin/reports?status={state}&page=0&size=50', token=ayman)['items']
            require(sum(x['reason'] in report_reasons for x in filtered) == expected_count,
                    f'administrator lifecycle filter {state}')
        announcement_admin = find(presentation_queue, 'reason',
                                  'This appears to duplicate the earlier prototype registration promotion.')
        announcement_detail = api.call('GET', f"/api/v1/admin/reports/{announcement_admin['id']}", token=ayman)
        require(announcement_detail['action']['source'] == 'PUBLICATION'
                and announcement_detail['action']['actionType'] == 'REMOVED'
                and announcement_detail['action']['subjectType'] == 'ANNOUNCEMENT',
                'action-taken report exposes committed matching evidence to administrator')
        require(announcement_detail['targetSnapshot'] and announcement_detail['internalNotes']
                and [x['newStatus'] for x in announcement_detail['history']] ==
                ['SUBMITTED', 'UNDER_REVIEW', 'ACTION_TAKEN'],
                'administrator sees retained snapshot, notes, and ordered history')
        require(next(x for x in announcement_detail['history'] if x['eventType'] == 'UNDER_REVIEW')['internalNote'] is None,
                'review-claim audit contains no impossible internal note')

        conversations = api.call('GET', '/api/v1/chat/conversations?page=0&size=50', token=zubair)['items']
        require(any(x['unreadCount'] > 0 for x in conversations), 'chat unread example visible')
        notifications = api.call('GET', '/api/v1/notifications?page=0&size=50', token=farhan)['items']
        require(any(x['readAt'] is None for x in notifications), 'unread notification visible')
        print('Presentation API checks completed without consuming pending actions.')
    finally:
        api.close()


if __name__ == '__main__':
    try:
        main()
    except (CheckError, URLError, KeyError, ValueError, StopIteration) as error:
        print('FAIL:', str(error) if isinstance(error, CheckError) else type(error).__name__)
        raise SystemExit(1)
