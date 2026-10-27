import argparse
import json
import re
import threading
import urllib.error
import urllib.request
import uuid

from smtp_test_sink import SmtpTestSink


def request(base_url, path, expected, body=None, token=None, method="POST"):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    payload = json.dumps(body).encode() if body is not None else None
    call = urllib.request.Request(base_url + path, data=payload, headers=headers, method=method)
    try:
        response = urllib.request.urlopen(call, timeout=15)
    except urllib.error.HTTPError as error:
        response = error
    assert response.status == expected, f"{path}: expected {expected}, received {response.status}"
    content = response.read()
    return json.loads(content) if content else None


def next_code(sink):
    body = sink.next_body()
    assert "http://" not in body and "https://" not in body, "Email unexpectedly contains a link"
    codes = re.findall(r"\b[0-9]{6}\b", body)
    assert len(codes) == 1, "Expected exactly one six-digit code"
    return codes[0]


def run(base_url, sink):
    email = f"recovery-smoke-{uuid.uuid4().hex[:12]}@iut-dhaka.edu"
    original = "SmokeOriginal123!"
    replacement = "SmokeReplacement456!"
    request(base_url, "/api/v1/auth/register", 201, {
        "fullName": "Recovery Smoke Test",
        "email": email,
        "password": original,
        "platformRole": "STUDENT",
    })
    request(base_url, "/api/v1/auth/verify-email", 204, {"email": email, "code": next_code(sink)})
    session = request(base_url, "/api/v1/auth/login", 200, {"email": email, "password": original})
    request(base_url, "/api/v1/auth/forgot-password", 202, {"email": email})
    code = next_code(sink)
    wrong = "000001" if code == "000000" else "000000"
    failure = request(base_url, "/api/v1/auth/reset-password", 400, {
        "email": email, "code": wrong, "newPassword": replacement,
    })
    assert failure["code"] == "INVALID_PASSWORD_RESET_CODE"
    request(base_url, "/api/v1/auth/verify-password-reset-code", 204, {"email": email, "code": code})
    request(base_url, "/api/v1/auth/reset-password", 204, {
        "email": email, "code": code, "newPassword": replacement,
    })
    request(base_url, "/api/v1/auth/reset-password", 400, {
        "email": email, "code": code, "newPassword": replacement,
    })
    request(base_url, "/api/v1/auth/me", 401, token=session["accessToken"], method="GET")
    request(base_url, "/api/v1/auth/refresh", 401, {"refreshToken": session["refreshToken"]})
    request(base_url, "/api/v1/auth/login", 401, {"email": email, "password": original})
    request(base_url, "/api/v1/auth/login", 200, {"email": email, "password": replacement})
    request(base_url, "/api/v1/auth/forgot-password", 202, {"email": "unknown@iut-dhaka.edu"})
    print("PASS: real HTTP + local SMTP registration, verification, recovery, wrong-code retry, replay rejection, password change and all-session revocation.", flush=True)


def main():
    parser = argparse.ArgumentParser(description="Run recovery against an isolated local backend and SMTP sink.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8087")
    parser.add_argument("--keep-serving", action="store_true")
    args = parser.parse_args()
    sink = SmtpTestSink()
    sink.start()
    try:
        run(args.base_url, sink)
        if args.keep_serving:
            print("Local SMTP fixture remains available on 127.0.0.1:1026; no external email is delivered.", flush=True)
            threading.Event().wait()
    finally:
        sink.close()


if __name__ == "__main__":
    main()
