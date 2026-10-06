# Zerodha Bug Bounty: Scope and Recon Notes

**Date:** 2026-10-05  
**Status:** Partial, read-only reconnaissance  
**Scope source:** Initial recon scope was researcher-provided. A scope table supplied on 2026-10-06 is recorded below; program policy was not independently verified.

## Authorized Scope

The current working record reflects the researcher-supplied scope table dated 2026-10-06. This was not independently verified against the program policy and is treated as a record of what was supplied, not as a legal or contractual statement of authorization.

- Primary: `*.zerodha.com/*`
- Other authorized targets: `https://api.kite.trade`, `*.zerodha.net/*`, `*zerodhacapital.com/*`
- Android apps: Kite by Zerodha, Coin by Zerodha, Pulse by Zerodha
- iOS apps: Kite by Zerodha, Coin by Zerodha

### Supplied scope table (2026-10-06)

- `*.zerodha.com/*` — Wildcard — `0.0.0.0/32` — High engagement
- `https://api.kite.trade` — API — `0.0.0.0/32` — Moderate engagement
- `https://play.google.com/store/apps/details?id=com.zerodha.kite3&hl=en_IN&gl=US` — Android: Play Store — `0.0.0.0/32` — Low engagement
- `https://play.google.com/store/apps/details?id=com.zerodha.coin&hl=en_IN&gl=US` — Android: Play Store — `0.0.0.0/32` — High engagement
- `https://play.google.com/store/apps/details?id=com.zerodha.pulse&hl=en_IN&gl=US` — Android: Play Store — `0.0.0.0/32` — High engagement
- `https://apps.apple.com/in/app/kite-zerodha/id1449453802` — iOS: App Store — `0.0.0.0/32` — Low engagement
- `https://apps.apple.com/in/app/coin-by-zerodha/id1392892554` — iOS: App Store — `0.0.0.0/32` — Moderate engagement
- `*zerodhacapital.com/*` — Any — `0.0.0.0/32` — Low engagement
- `*.zerodha.net/*` — Any — `0.0.0.0/32` — Moderate engagement

### Engagement summary from the supplied table

- High: `*.zerodha.com/*`; Coin for Android; Pulse for Android
- Moderate: `https://api.kite.trade`; Coin for iOS; `*.zerodha.net/*`
- Low: Kite for Android; Kite for iOS; `*zerodhacapital.com/*`

The `0.0.0.0/32` string in the IP Address column was present for every row. This is recorded as supplied metadata only; it does not identify a target IP or expand authorization. The app store URLs identify the listed apps and are not themselves authorization to test the app stores or unrelated services.

## Out-of-Scope Systems

- `https://zerodha.com/varsity/*`
- `https://varsitylive.zerodha.com/*`
- Zerodha Varsity Android app
- Zerodha Varsity iOS app
- `https://kite.trade/forum/*`
- `https://developers.kite.trade/*`
- Newsletters via SubStack
- Sensibull
- Sentinel
- Smallcase
- `https://streak.zerodha.com/*` (Streaks)
- `https://fd.zerodha.com/*` (Zerodha FD)
- Any unlisted or uncertain host, third-party infrastructure, CDN/analytics/advertising infrastructure, and redirect destinations outside authorized scope

## Explicit Exclusions

- `https://zerodha.com/varsity/*`
- `https://varsitylive.zerodha.com/*`
- Zerodha Varsity Android and iOS apps
- `https://kite.trade/forum/*`
- `https://developers.kite.trade/*`
- `https://streak.zerodha.com/*` (Streaks)
- `https://fd.zerodha.com/*` (Zerodha FD)
- Sensibull, Sentinel, Smallcase, newsletters/SubStack
- All unlisted or uncertain hosts, third-party infrastructure, CDN/analytics/advertising infrastructure, and redirect destinations outside authorized scope

Do not infer authorization from ownership, DNS, certificates, IPs, links, JavaScript references, `robots.txt`, or redirects. Do not test uncertain assets. Use only researcher-controlled accounts/resources if authenticated testing is later authorized. No real trades, funds movement, cross-user access, account enumeration, or destructive actions.

## Recon Method and Limits

- HexStrike and browser network/HAR capture were not available in this environment. No researcher-controlled authenticated session was shared, and no Burp traffic was provided.
- In addition to the earlier `HEAD` and `GET` to `kite.zerodha.com/`, performed one unauthenticated `GET /` to each of the seven exact priority hosts listed in the follow-up request. All match the explicitly authorized `*.zerodha.com` wildcard. The local HTTPx evidence in `/home/abarnesh/BugBounty/targets/zerodha/recon/tier-a-httpx.txt` was consulted for root titles/statuses only.
- Redirects were not followed. No other discovered or inferred host was requested, and no third-party resource was loaded.
- No authentication, account actions, application API calls, enumeration, or vulnerability validation was performed. Root responses do not establish authenticated behavior or identify APIs called by the browser.
- This is a partial public-entry baseline, not a complete attack-surface map. Do not treat absent coverage as evidence that other paths or behaviors are safe.

## Prioritized Observations

### Kite login entry point

- **TARGET:** `*.zerodha.com/*`
- **HOST:** `kite.zerodha.com`
- **PATH:** `/`
- **METHOD:** `HEAD`, `GET`
- **SCOPE STATUS:** In scope; hostname matches the explicitly authorized wildcard
- **AUTH REQUIRED:** No authentication required to retrieve the root login shell; account access was not attempted
- **FUNCTION:** Kite login entry page
- **PARAMETERS:** None observed in the root URL
- **OBSERVED BEHAVIOR:** `HEAD /` returned HTTP `405` with `Allow: GET, OPTIONS`. `GET /` returned HTTP `200` and HTML identifying the Kite login page. HTML referenced Vue library bundles and same-origin `/static/js/` and `/static/css/` assets; those assets were not fetched. The response included Cloudflare edge headers; origin technology is unknown.
- **POTENTIAL VULNERABILITY:** None evidenced. Method handling, framework references, and response headers alone are not findings.
- **POTENTIAL SECURITY IMPACT:** None established
- **EVIDENCE:** Direct responses from `kite.zerodha.com/` on 2026-10-05. Session and bot-mitigation cookie values intentionally omitted.
- **SAFE MANUAL VALIDATION:** No further validation performed. Any future checks should remain on explicitly in-scope hosts, use researcher-controlled resources, and stop before financial or cross-user impact.
- **PRIORITY:** FALSE POSITIVE (no vulnerability demonstrated)

## Current Result

## Priority Host Application Baseline

Only root requests were made. `STATE-CHANGING` below describes the observed request, not unobserved actions inside each application. No API endpoint beyond `/` was observed in browser traffic.

### Kite

- **HOST:** `kite.zerodha.com`
- **PATH:** `/`
- **METHOD:** `HEAD`, `GET`
- **AUTHENTICATION:** Root login page is publicly retrievable; no authenticated session was used.
- **PARAMETERS:** None observed.
- **FUNCTION:** Kite login entry page, identified by page title and HTML description.
- **STATE-CHANGING:** NO (root retrieval only).
- **USER-CONTROLLED IDENTIFIERS:** None observed.
- **POTENTIAL AUTHORIZATION BOUNDARY:** Login boundary is visible; post-login session and resource authorization boundaries are unobserved.
- **INTERESTING BEHAVIOR:** `HEAD` returned `405` with `Allow: GET, OPTIONS`; `GET` returned `200` HTML. The page referenced same-origin static JavaScript/CSS assets, which were not fetched.
- **SAFE NEXT TEST:** Review a sanitized researcher-session HAR for normal login and read-only page loads; redact credential/token values.
- **PRIORITY:** LOW PRIORITY (surface baseline only; no issue evidenced).

### Console

- **HOST:** `console.zerodha.com`
- **PATH:** `/`
- **METHOD:** `GET`
- **AUTHENTICATION:** Root returned public HTML titled `Console Login: Zerodha`; no authenticated session was used.
- **PARAMETERS:** None observed.
- **FUNCTION:** Console login entry page, based on the HTTPx page title.
- **STATE-CHANGING:** NO (root retrieval only).
- **USER-CONTROLLED IDENTIFIERS:** None observed.
- **POTENTIAL AUTHORIZATION BOUNDARY:** Login boundary is visible; authenticated console roles and resource identifiers are unobserved.
- **INTERESTING BEHAVIOR:** HTTP `200`, `text/html`; no redirect followed.
- **SAFE NEXT TEST:** Review a sanitized researcher-session HAR for normal login and read-only views; redact credential/token values.
- **PRIORITY:** LOW PRIORITY (surface baseline only; no issue evidenced).

### Signup

- **HOST:** `signup.zerodha.com`
- **PATH:** `/`
- **METHOD:** `GET`
- **AUTHENTICATION:** Root returned public HTML titled `Signup to open a zerodha account`; no account creation was initiated.
- **PARAMETERS:** None observed.
- **FUNCTION:** Signup entry page, based on the HTTPx page title.
- **STATE-CHANGING:** NO (root retrieval only; no form was submitted).
- **USER-CONTROLLED IDENTIFIERS:** None observed.
- **POTENTIAL AUTHORIZATION BOUNDARY:** Registration/identity verification boundary is suggested by the page title; workflow and identifiers are unobserved.
- **INTERESTING BEHAVIOR:** HTTP `200`, `text/html`.
- **SAFE NEXT TEST:** Inspect normal signup-page traffic without submitting personal or identity data; use only researcher-controlled test data if the program explicitly permits it.
- **PRIORITY:** LOW PRIORITY (surface baseline only; no issue evidenced).

### Account

- **HOST:** `account.zerodha.com`
- **PATH:** `/`
- **METHOD:** `GET`
- **AUTHENTICATION:** No session was used. Root returned HTTP `301` with `Location: http://account.zerodha.com/account`; the redirect was not followed.
- **PARAMETERS:** No request parameters observed. Redirect location contains no query string.
- **FUNCTION:** Account entry point is not confirmed because the destination was not requested.
- **STATE-CHANGING:** NO (root retrieval only).
- **USER-CONTROLLED IDENTIFIERS:** None observed.
- **POTENTIAL AUTHORIZATION BOUNDARY:** Unknown; authentication and account-resource behavior were not observed.
- **INTERESTING BEHAVIOR:** The HTTPS root advertises an HTTP destination on the same in-scope host. No plaintext request was made; this observation alone is not treated as a vulnerability.
- **SAFE NEXT TEST:** Do not follow the HTTP redirect with credentials. Confirm the intended secure account URL through program documentation or researcher-controlled browser traffic.
- **PRIORITY:** LOW PRIORITY (redirect observation only; no issue declared).

### Cashier

- **HOST:** `cashier.zerodha.com`
- **PATH:** `/`
- **METHOD:** `GET`
- **AUTHENTICATION:** No session was used. Root returned HTTP `303` with `Location: https://cashier.zerodha.com/login?next_url=%2F`; the redirect was not followed.
- **PARAMETERS:** The response redirect includes `next_url=%2F`; it was not supplied by the client request and was not tested.
- **FUNCTION:** Login-gated cashier entry is suggested by the redirect path; financial workflows were not opened or exercised.
- **STATE-CHANGING:** NO (root retrieval only).
- **USER-CONTROLLED IDENTIFIERS:** None observed.
- **POTENTIAL AUTHORIZATION BOUNDARY:** Login boundary is suggested; payment/fund operations and authorization checks remain unobserved.
- **INTERESTING BEHAVIOR:** Redirect stays on the same explicitly in-scope host. No login or financial action was attempted.
- **SAFE NEXT TEST:** Review researcher-controlled, read-only cashier navigation traffic; stop before any deposit, withdrawal, or transfer confirmation.
- **PRIORITY:** LOW PRIORITY (surface baseline only; no issue evidenced).

### OTP

- **HOST:** `otp.zerodha.com`
- **PATH:** `/`
- **METHOD:** `GET`
- **AUTHENTICATION:** No session was used; response was `200`, `text/plain`.
- **PARAMETERS:** None observed.
- **FUNCTION:** Unknown from the root response metadata; no OTP flow was initiated.
- **STATE-CHANGING:** NO (root retrieval only).
- **USER-CONTROLLED IDENTIFIERS:** None observed.
- **POTENTIAL AUTHORIZATION BOUNDARY:** Unknown; no authentication challenge or verification request was observed.
- **INTERESTING BEHAVIOR:** Plain-text response type only; body was not used to infer a function.
- **SAFE NEXT TEST:** Capture only a normal researcher-controlled challenge flow if needed; never trigger messages to another person or repeatedly request codes.
- **PRIORITY:** LOW PRIORITY (surface baseline only; no issue evidenced).

### Kite UAT API

- **HOST:** `kite-uat-api.zerodha.com`
- **PATH:** `/`
- **METHOD:** `GET`
- **AUTHENTICATION:** No session was used; response was `200`, `application/json`.
- **PARAMETERS:** None observed.
- **FUNCTION:** Unknown from root response metadata; no API operation was called.
- **STATE-CHANGING:** NO (root retrieval only).
- **USER-CONTROLLED IDENTIFIERS:** None observed.
- **POTENTIAL AUTHORIZATION BOUNDARY:** Unknown; no API authentication or resource authorization behavior was observed.
- **INTERESTING BEHAVIOR:** JSON content type at the root; response body was not used to infer API semantics.
- **SAFE NEXT TEST:** Review sanitized requests from a researcher-controlled UAT session, limited to documented read-only calls; do not replay mutations.
- **PRIORITY:** LOW PRIORITY (surface baseline only; no issue evidenced).

## Current Result

No vulnerability is declared. This baseline does not identify application API calls, methods beyond root retrieval, auth/session token boundaries, authorization-relevant identifiers, or state-changing operations. Those require browser/Burp traffic from a researcher-controlled session. No other host was tested; no redirect was followed; the account and cashier destinations remain unvisited.
