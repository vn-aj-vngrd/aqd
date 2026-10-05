#!/usr/bin/env python3
"""Exercise the real local Supabase API. Never run against a hosted database."""
import base64
import hashlib
import json
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timezone

status = json.loads(subprocess.check_output(["supabase", "status", "--output", "json"], stderr=subprocess.DEVNULL))
base = status["API_URL"]
assert urllib.parse.urlparse(base).hostname in ("127.0.0.1", "localhost"), "Local tests only"
key = status["PUBLISHABLE_KEY"]
admin = status["SERVICE_ROLE_KEY"]
created = []
uploaded = []
checks = 0


def request(path, method="GET", payload=None, token=None, headers=None, binary=None):
    body = binary if binary is not None else json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(base + path, data=body, method=method, headers={
        "apikey": key, "Authorization": "Bearer " + (token or key),
        "Content-Type": "application/json", **(headers or {})})
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        raw = error.read()
        return error.code, json.loads(raw) if raw else None


def expect(condition, label):
    global checks
    assert condition, label
    checks += 1
    print("PASS " + label)


def account():
    email = "aqd-" + uuid.uuid4().hex + "@example.test"
    password = uuid.uuid4().hex + "!aA1"
    code, user = request("/auth/v1/admin/users", "POST", {"email": email, "password": password, "email_confirm": True}, admin)
    assert code == 200
    created.append(user["id"])
    code, session = request("/auth/v1/token?grant_type=password", "POST", {"email": email, "password": password})
    assert code == 200
    return user["id"], session["access_token"]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


try:
    owner, token = account()
    other, other_token = account()
    for invalid in (None, []):
        code, _ = request("/rest/v1/rpc/connect_closet", "POST", {"p_operation_id": str(uuid.uuid4()), "p_pieces": invalid}, token)
        expect(code >= 400, "null/empty association payload cannot claim success")
    piece = {"id": str(uuid.uuid4()), "name": "Everyday shoes", "category": "shoes", "created_at": datetime.now(timezone.utc).isoformat()}
    operation = str(uuid.uuid4())
    payload = {"p_operation_id": operation, "p_pieces": [piece]}
    code, _ = request("/rest/v1/rpc/connect_closet", "POST", payload)
    expect(code in (401, 403), "guest cannot connect a closet")
    code, receipt = request("/rest/v1/rpc/connect_closet", "POST", payload, token)
    expect(code == 200 and receipt["piece_ids"] == [piece["id"]], "owner receives confirmed connection receipt")
    code, replay = request("/rest/v1/rpc/connect_closet", "POST", payload, token)
    expect(code == 200 and replay == receipt, "retry returns the same receipt without duplicate records")
    code, rows = request("/rest/v1/private_pieces?select=id,name", token=token)
    expect(code == 200 and len(rows) == 1 and rows[0]["name"] == "Everyday shoes", "owner can restore actual saved records")
    code, rows = request("/rest/v1/private_pieces?select=id", token=other_token)
    expect(code == 200 and rows == [], "another account cannot read private pieces")
    code, rows = request("/rest/v1/closet_connections?select=operation_id", token=other_token)
    expect(code == 200 and rows == [], "another account cannot read receipts")
    code, _ = request("/rest/v1/rpc/connect_closet", "POST", payload, other_token)
    expect(code >= 400, "another account cannot replay the owners operation")
    changed = {**payload, "p_pieces": [{**piece, "name": "Replaced"}]}
    code, _ = request("/rest/v1/rpc/connect_closet", "POST", changed, token)
    expect(code >= 400, "an operation ID cannot be reused with changed content")
    code, error = request("/rest/v1/rpc/connect_closet", "POST", {**payload, "p_operation_id": str(uuid.uuid4())}, token)
    expect(code >= 400 and "closet_conflict" in error.get("message", ""), "existing account closet cannot be overwritten")
    code, _ = request("/rest/v1/private_pieces", "POST", {**piece, "owner_id": other}, token)
    expect(code in (401, 403), "direct writes cannot bypass reviewed association")
    code, _ = request("/rest/v1/rpc/connect_closet", "POST", {"p_operation_id": str(uuid.uuid4()), "p_pieces": [{**piece, "id": str(uuid.uuid4())}, {**piece, "id": str(uuid.uuid4()), "category": "invalid"}]}, other_token)
    assert code >= 400
    code, rows = request("/rest/v1/private_pieces?select=id", token=other_token)
    expect(rows == [], "a partially invalid connection rolls back every piece")
    username = "entry_" + uuid.uuid4().hex[:12]
    code, _ = request("/rest/v1/profiles", "POST", {"id": owner, "display_name": "Entry test", "username": username}, token)
    expect(code == 201, "signed-in user can create a public identity")
    code, _ = request("/rest/v1/profiles", "POST", {"id": other, "display_name": "Other", "username": username.upper()}, other_token)
    expect(code == 409, "username uniqueness is case-insensitive")
    code, _ = request("/rest/v1/profiles?id=eq." + owner, "PATCH", {"id": other}, token)
    expect(code >= 400, "a profile cannot transfer its ownership")
    path = owner + "/" + operation + "/" + piece["id"] + ".jpg"
    # Minimal valid JPEG fixture; storage must enforce ownership independently of the UI.
    jpeg = base64.b64decode("/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAf/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAf/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAB//2Q==")
    code, _ = request("/storage/v1/object/closet/" + path, "POST", token=token, binary=jpeg, headers={"Content-Type": "image/jpeg"})
    expect(code == 200, "owner can upload private photo media")
    uploaded.append(path)
    code, _ = request("/storage/v1/object/sign/closet/" + path, "POST", {"expiresIn": 60}, other_token)
    expect(code >= 400, "another account cannot sign private media URLs")
    code, _ = request("/storage/v1/object/closet/" + path, "PUT", token=other_token, binary=jpeg, headers={"Content-Type": "image/jpeg"})
    expect(code >= 400, "another account cannot replace private media")
    photo_id, photo_operation = str(uuid.uuid4()), str(uuid.uuid4())
    photo_path = other + "/" + photo_operation + "/" + photo_id + ".jpg"
    code, _ = request("/storage/v1/object/closet/" + photo_path, "POST", token=other_token, binary=jpeg, headers={"Content-Type": "image/jpeg"})
    assert code == 200
    uploaded.append(photo_path)
    code, receipt = request("/rest/v1/rpc/connect_closet", "POST", {"p_operation_id": photo_operation.upper(), "p_pieces": [{**piece, "id": photo_id.upper(), "photo_path": photo_path}]}, other_token)
    expect(code == 200 and receipt["piece_ids"] == [photo_id], "Swift UUID casing associates actual private photo media")
    # Exercise real email delivery and a PKCE code exchange through the local inbox.
    email = "magic-" + uuid.uuid4().hex + "@example.test"
    verifier = uuid.uuid4().hex + uuid.uuid4().hex
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).decode().rstrip("=")
    state = str(uuid.uuid4())
    redirect = "com.aqd.ios://auth/callback?state=" + state
    code, _ = request("/auth/v1/otp?redirect_to=" + urllib.parse.quote(redirect, safe=""), "POST", {"email": email, "code_challenge": challenge, "code_challenge_method": "s256"})
    expect(code == 200, "real Supabase email request succeeds")
    message = None
    mail = status.get("MAILPIT_URL", status["INBUCKET_URL"])
    for _ in range(20):
        with urllib.request.urlopen(mail + "/api/v1/messages", timeout=10) as response:
            messages = json.load(response).get("messages", [])
        match = next((item for item in messages if any(recipient.get("Address") == email for recipient in item.get("To", []))), None)
        if match:
            with urllib.request.urlopen(mail + "/api/v1/message/" + match["ID"], timeout=10) as response:
                message = json.load(response)
            break
        time.sleep(0.25)
    expect(message is not None, "local inbox receives the actual sign-in link")
    link = re.search(r'href="([^"]*\/auth\/v1\/verify[^\"]+)"', message["HTML"])[1].replace("&amp;", "&")
    opener = urllib.request.build_opener(NoRedirect)
    try:
        opener.open(link)
        raise AssertionError("Expected redirect")
    except urllib.error.HTTPError as response:
        callback = response.headers["Location"]
    params = urllib.parse.parse_qs(urllib.parse.urlparse(callback).query)
    expect(params.get("state") == [state] and "code" in params, "callback retains initiating state with a PKCE code")
    code, session = request("/auth/v1/token?grant_type=pkce", "POST", {"auth_code": params["code"][0], "code_verifier": verifier})
    expect(code == 200 and session["user"]["email"] == email, "PKCE email verification creates the real account session")
    created.append(session["user"]["id"])
    code, _ = request("/auth/v1/token?grant_type=pkce", "POST", {"auth_code": params["code"][0], "code_verifier": verifier})
    expect(code >= 400, "consumed sign-in codes cannot be replayed")
    print(f"{checks} connected local backend checks passed")
finally:
    # Remove uploaded test media before deleting its owners.
    if uploaded:
        code, _ = request("/storage/v1/object/closet", "DELETE", {"prefixes": uploaded}, admin)
        assert code == 200, "Test media cleanup failed"
    # Test-only accounts, never real user identities.
    for user in created:
        code, _ = request("/auth/v1/admin/users/" + user, "DELETE", token=admin)
        assert code == 200, "Test account cleanup failed"
