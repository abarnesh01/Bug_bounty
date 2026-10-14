# Vinted Bug Bounty — Rigorous Evidence Analysis
Date: 2026-10-14 | Phase: Evidence review only — no new network requests
Instruction: Separate fact / assumption / unsupported. No tokens, cookies, or PII in output.

---

## Legend
- FACT        — Directly observed in a captured HTTP response or decoded locally
- ASSUMPTION  — Plausible inference; not demonstrated by a request/response pair
- UNSUPPORTED — Stated in prior reports without evidence; must be dropped or validated
- SCOPE       — Scope determination per Bugcrowd brief
- EXCLUDED    — Explicitly excluded by program rules

---

## F1 — ServiceNow inline JavaScript disclosure
Target: test-escalations.vintedgo.com | Prior label: P2–P3

### Evidence Inventory

| Claim | Status | Source |
|---|---|---|
| Platform is ServiceNow, not Angular | FACT | server:snow_adc header; glide_user_route cookie; window.NOW.* globals in HTML |
| window.g_ck present in unauthenticated page source | FACT | curl .../csm?id=csm_index confirmed value present |
| window.NOW.session_id / user_id / user_name='guest' in source | FACT | Same curl, values confirmed |
| glide_node_id_for_js cookie set without login | FACT | Cookie jar from unauthenticated request |
| /api/now/table/sn_customerservice_case returns 401 as guest | FACT | Tested — HTTP 401 confirmed |
| /api/now/sp/page?id=csm_index returns HTTP 200 as guest | FACT | Confirmed; response parsed |
| sp/page response contains guest user object (logged_in:false) | FACT | Parsed JSON — all values are ServiceNow built-in guest account, not a real person |
| window.g_ck can authenticate ServiceNow REST API calls | UNSUPPORTED | g_ck is a CSRF token. All /api/now/table/* returned 401 regardless of g_ck being sent. |
| Support cases contain real customer PII | UNSUPPORTED | No case was created or accessed. |
| Guests can enumerate other users' cases | UNSUPPORTED | Not tested. No case was accessed. |
| This is a "sensitive internal tool" | ASSUMPTION | Vinted explicitly lists this in secondary scope — it is intentionally externally accessible. |

### Security Boundary Analysis

The core claim is that the inline g_ck token is a dangerous exposure.

What g_ck actually is: In ServiceNow, glide_ck is an anti-CSRF token scoped to
the current guest session. It is generated per-session, not a persistent credential,
and requires a valid authenticated session cookie alongside it to perform privileged
API operations. Standard ServiceNow CSP behaviour.

The /api/now/sp/page HTTP 200 response returns only the ServiceNow built-in guest user
object (logged_in:false, email:guest@example.com). This is not a real person's data.
This is standard ServiceNow CSP portal design — the endpoint is intentionally public.

Genuine boundary failure demonstrated? No.
The REST table API (/api/now/table/*) is properly gated at HTTP 401.

Genuine reportable surface (unvalidated): Whether a registered user can access another
user's support cases by manipulating sys_id values. Requires a test account.

### Corrected Assessment
Status: Surface identified. No security boundary failure demonstrated.
Do NOT report g_ck or sp/page disclosure as standalone findings — Bugcrowd will reject them.
Next step: Authenticated case-IDOR test (see Validation Plan).

---

## F2 — F5 BIG-IP Persistence Cookie
Target: test-escalations.vintedgo.com | Prior label: P3–P4

### Evidence Inventory

| Claim | Status | Source |
|---|---|---|
| Cookie BIGipServerpool_testsupportvintedgo is set | FACT | Captured cookie jar |
| Cookie decoded to IP [REDACTED — decoded IP] port 61479 | FACT | Local Python decode (little-endian) |
| [REDACTED — decoded IP] is a public (non-RFC-1918) IP | FACT | ipaddress.is_private == False confirmed |
| This is a Vinted-controlled internal backend server | UNSUPPORTED | IP is public/global. Consistent with ServiceNow cloud infrastructure, not Vinted's own network. |
| This constitutes "internal IP disclosure" | UNSUPPORTED | IP is public, not private. No internal network range is exposed. |

### Corrected Assessment
Status: FALSE POSITIVE.
The decoded IP is a public global IP — consistent with ServiceNow's cloud infrastructure.
BIG-IP cookie IP disclosure is only meaningful when the IP is RFC 1918 private.
Do NOT report. Bugcrowd will reject this.

---

## F3 — carrier.vintedgo.com tracking API URL in page source
Target: carrier.vintedgo.com | Prior label: P2–P3

### Evidence Inventory

| Claim | Status | Source |
|---|---|---|
| String "trackingUrl":"https://carrier.vintedgo.com/public/v3/tracking_events" in page source | FACT | grep on curl of vintedgo.com/fr/tracking confirmed |
| carrier.vintedgo.com responds HTTP 200 at root | FACT | curl -I confirmed |
| Endpoint returns tracking events without authentication | UNSUPPORTED | All tested paths returned 404. No real tracking number tested. |
| Endpoint reveals sender/receiver address | UNSUPPORTED | No response body observed. Completely speculative. |
| Sequential tracking numbers are enumerable | UNSUPPORTED | Format inferred from UI placeholder only. Not tested with real data. |

### Scope
carrier.vintedgo.com is NOT in the Bugcrowd scope list (primary or secondary).
Per program rules: out-of-scope subdomains can be reported only if a genuine
security vulnerability is demonstrated. No vulnerability is demonstrated here.

### Corrected Assessment
Status: Endpoint URL discovered in page source. Zero evidence of security failure.
Do NOT report at this stage — the finding is "a URL string exists in page source."
Validation plan (below) describes safe next steps.

---

## F4 — Yopass at badger.it.vinted.com
Target: badger.it.vinted.com | Prior label: P2–P3

### Evidence Inventory

| Claim | Status | Source |
|---|---|---|
| badger.it.vinted.com is publicly accessible | FACT | HTTP 200 root response |
| Platform is Yopass | FACT | Page title, GitHub link, UI structure |
| /config returns JSON HTTP 200 with no auth | FACT | Live HTTP response |
| FORCE_ONETIME_SECRETS: false | FACT | In config JSON |
| PREFETCH_SECRET: true | FACT | In config JSON |
| /health returns {"status":"healthy"} HTTP 200 | FACT | Live HTTP response |
| Secrets require PGP encryption | FACT | API returned "Message must be PGP encrypted" on plaintext POST |
| No authentication required to access the service | FACT | Design-level — confirmed no auth gate |
| Vinted staff use this to share credentials | UNSUPPORTED | No evidence. Plausible inference only. |
| Any UUID has been leaked externally | UNSUPPORTED | No Wayback or GitHub results found. |
| PREFETCH_SECRET creates timing/cache attack | ASSUMPTION | Requires PGP private key to decrypt ciphertext. Minimal practical risk. |
| UUID brute-force is feasible | UNSUPPORTED | v4 UUID = 128-bit random. Infeasible. Correctly disclaimed in notes. |

### Scope
badger.it.vinted.com is explicitly listed in Secondary targets as "Encryption Service." IN SCOPE.

### Security Boundary Analysis

Genuine observation: public secret-sharing service, no authentication wall,
intentional design per Yopass model (UUID secrecy + PGP encryption = security model).

FORCE_ONETIME_SECRETS: false is the only configuration item that weakens the security
model. It allows creation of reusable secrets. If such a secret's UUID is disclosed,
the secret can be read repeatedly. This is a configuration risk, not a direct exploit.

What this is NOT: access control bypass, IDOR, or credential exposure without
a precondition (the precondition being: a UUID must be separately leaked).

### Corrected Assessment
Status: Genuine configuration-level concern. Not directly exploitable.
Reportable as P4 (informational/configuration). Draft report in Section 3.

---

## F5 — JWT aud field discloses internal hostname
Target: www.vinted.com | Prior label: P2

### Evidence Inventory

| Claim | Status | Source |
|---|---|---|
| access_token_web JWT issued to unauthenticated visitors | FACT | Browser inspection |
| JWT aud = fr.core.api.vinted.com | FACT | Decoded locally |
| JWT algorithm = PS256 | FACT | alg header confirmed |
| No public JWKS endpoint found | FACT | All candidate paths returned 404 |
| fr.core.api.vinted.com is an internal hostname | ASSUMPTION | Not in public docs; consistent with internal routing |
| Changing app_id bypasses restrictions | UNSUPPORTED | PS256 signed — modification invalidates signature |
| scope: public can be escalated server-side | UNSUPPORTED | Not tested |

### Corrected Assessment
Status: Informational reconnaissance value only.
The aud field is a JWT design element — reading your own token's claims is not a bypass.
Do NOT report.

---

## F6/F7 — Missing Security Headers
Targets: www.vintedgo.com, www.vinted.com
EXCLUDED — explicitly listed as non-qualifying in the Bugcrowd program brief.
Remove from all reports.

---

## False Assumptions Register

| # | Claim | Why it is wrong |
|---|---|---|
| 1 | g_ck token authenticates ServiceNow API calls | All /api/now/table/* returned 401 regardless of g_ck. It is a CSRF token, not auth. |
| 2 | BIG-IP cookie reveals internal backend IP | Decoded IP [REDACTED — decoded IP] is a public global IP. Not Vinted's internal network. |
| 3 | carrier.vintedgo.com tracking API accessible without auth | 404 on all paths tested. No real tracking number used. Auth behaviour unknown. |
| 4 | JWT app_id / scope can be manipulated | PS256 signed. Modification invalidates signature. No private key available. |
| 5 | ServiceNow portal is a sensitive internal tool | It is listed in Bugcrowd scope — Vinted intentionally exposes it for testing. |
| 6 | Yopass is used to share production credentials | No evidence. Speculative. |
| 7 | Sequential tracking numbers are enumerable | Format inferred from placeholder only. Enumeration also violates program rules. |
| 8 | PREFETCH_SECRET is a timing/cache attack | Requires PGP private key to exploit. Low practical risk. |
| 9 | sp/page API returning guest object is a data leak | The user object is ServiceNow's built-in anonymous account, not a real person's data. |
| 10 | ServiceNow case IDOR exists | No case created or accessed. Entirely unverified. |

---

## Strongest Candidate for Authorized Validation

### ServiceNow CSP Case IDOR — test-escalations.vintedgo.com

Why this is the priority:
- In scope (Secondary targets, Bugcrowd brief)
- Real security question: does the portal enforce record ownership on support cases?
- ServiceNow CSP portals have a known pattern of insufficient access control on cases
- Impact if confirmed: VintedGo customer support records exposed
- Requires only researcher-owned data to validate safely

Safe Validation Plan (no rule violations):

Step 1: Register test account A at /csm?id=csm_registration (use @bugcrowdninja.com email)
Step 2: Submit one test support case — subject "Bug bounty test, please ignore"
Step 3: Note your case's sys_id from the URL or confirmation page
Step 4: Log out completely (fresh incognito window)
Step 5: Attempt to access your own case record as unauthenticated guest:
  GET /csm?id=sn_customerservice_case&sys_id={your_case_sys_id}
  Observe: blocked (expected) or visible (finding)?
Step 6: If visible unauthenticated — stop, document HTTP status + response structure
Step 7: Register test account B, attempt to view Account A's case while logged in as B
Step 8: Stop at first evidence of a boundary failure — do not read real customer data
Step 9: Do NOT access any case you did not create

Expected maximum impact if confirmed: P2 (unauthorized access to VintedGo support case data)
Reject conditions: if both steps 5 and 7 are blocked, finding is not valid.

---

## Sanitized Draft Report — Yopass Configuration

(The only finding where evidence is sufficient for submission)

Title: Yopass secret-sharing service at badger.it.vinted.com is publicly accessible
without authentication and does not enforce one-time secret policy

Target: https://badger.it.vinted.com (Secondary scope — Bugcrowd brief: "Encryption Service")
Severity (VRT): P4 — Sensitive Data Exposure / Configuration Weakness
CWE: CWE-16 (Configuration)

Summary
-------
Vinted operates a publicly accessible deployment of Yopass at badger.it.vinted.com.
The service requires no authentication. Its /config endpoint confirms FORCE_ONETIME_SECRETS
is false, meaning the service allows creation of reusable secrets that persist across
multiple reads. If a secret UUID is disclosed through secondary channels (git commit,
internal log, email thread), any internet user can retrieve the secret without credentials.

Steps to Reproduce
------------------
1. Navigate to https://badger.it.vinted.com — no login prompt is presented.

2. Issue GET https://badger.it.vinted.com/config with no credentials:

   Request:
     GET /config HTTP/2
     Host: badger.it.vinted.com

   Response:
     HTTP/2 200
     content-type: application/json
     access-control-allow-origin: *

     {
       "DEFAULT_EXPIRY": 3600,
       "DISABLE_FEATURES": false,
       "DISABLE_UPLOAD": false,
       "FORCE_ONETIME_SECRETS": false,
       "PREFETCH_SECRET": true,
       "READ_ONLY": false
     }

3. Issue GET https://badger.it.vinted.com/health with no credentials:

   Response: HTTP/2 200  {"status":"healthy"}

Impact
------
The service is reachable by any internet user. With FORCE_ONETIME_SECRETS false, a
staff member can create a non-expiring, reusable secret. Should its UUID be exposed
(Slack, email, git history, log file), an attacker can retrieve the payload — which
may contain credentials, API keys, or other material — with no authentication required.

The security model of Yopass relies on two things: UUID secrecy and PGP encryption.
FORCE_ONETIME_SECRETS false removes a server-side safeguard against repeated reads
when UUID secrecy is broken.

What Is NOT Claimed
-------------------
- No existing secrets were accessed or retrieved
- No credentials or keys were observed
- UUID brute-force is not feasible (v4 UUID, 128-bit random)
- No evidence that any UUID has been leaked

Suggested Fix
-------------
Either:
(a) Set FORCE_ONETIME_SECRETS: true in the Yopass server configuration, OR
(b) Restrict access to the service to Vinted's VPN / internal network only

---

## Final Summary Table

| Finding | Reportable? | Corrected Status | Action |
|---|---|---|---|
| F1 ServiceNow g_ck in page source | No (standalone) | No boundary failure demonstrated | Proceed to case IDOR validation |
| F2 BIG-IP cookie | No | FALSE POSITIVE — public IP decoded | Drop entirely |
| F3 carrier.vintedgo.com URL in source | No (yet) | URL found, no vuln demonstrated | Validate with own tracking number |
| F4 Yopass public + FORCE_ONETIME_SECRETS false | Yes (P4) | Config weakness, no direct exploit | Submit draft above or hold |
| F5 JWT aud hostname | No | Informational, not a vulnerability | Drop |
| F6/F7 Missing headers | No | Explicitly excluded by program | Remove from all reports |
| ServiceNow Case IDOR | Unvalidated — priority | Strongest candidate | Execute safe validation plan |
