# Vinted Bug Bounty — Confirmed Findings Summary
**Date**: 2026-10-14 | **Phase**: Passive Recon + Active Surface Mapping

---

## 🔴 HIGH PRIORITY — Requires Authenticated Manual Testing

### [F1] ServiceNow CSP Portal Exposes Session Data via Inline Scripts
**Target**: https://test-escalations.vintedgo.com
**Severity estimate**: P2-P3
**Type**: Information Disclosure / Potential Unauthenticated Data Access

**What we found:**
- `test-escalations.vintedgo.com` is a **ServiceNow CSM (Customer Service Management)** portal — NOT a simple Angular app
- Platform: ServiceNow (server: `snow_adc`, cookies: `glide_user_route`, `JSESSIONID`, `glide_node_id_for_js`)
- Load balancer: **F5 BIG-IP** (cookie: `BIGipServerpool_testsupportvintedgo`)
- Full session & user data leaked in inline JavaScript on every page load:

```javascript
window.NOW.session_id = '[REDACTED]';
window.NOW.user_name = 'guest';
window.NOW.user_id = '[REDACTED]';
window.g_ck = '[REDACTED — CSRF token]';
window.NOW.portal_id = '[REDACTED]';
window.NOW.instance_id = '64c13c2bdb7bd5d02f68c5970...';
```

- ServiceNow REST API (`/api/now/table/`) returns **401** as guest — properly blocked
- But **`/api/now/sp/page?id=csm_index`** returns full page configuration including user profile to unauthenticated visitors (HTTP 200):
  ```json
  "user": {
    "sys_id": "[REDACTED]",
    "email": "guest@example.com",
    "user_name": "guest",
    "logged_in": false
  }
  ```

**What to test next (with test account):**
1. Register at `/csm?id=csm_registration`
2. Submit a support case, then enumerate case IDs: `/csm?id=csm_my_lists`
3. Try accessing another user's case via sys_id from the portal API
4. Check if case data includes personal details of VintedGo customers

---

### [F2] F5 BIG-IP Persistence Cookie Leaks Backend Server IP
**Target**: https://test-escalations.vintedgo.com
**Severity estimate**: P4 (informational → P3 if private IP)
**Type**: Information Disclosure

**Cookie**: `BIGipServerpool_testsupportvintedgo = [REDACTED]`

**Decoded:**
```
IP (little-endian):  [REDACTED — decoded IP]
Port (little-endian): 61479
```
Note: [REDACTED — decoded IP] decodes to a public IP, suggesting the BIG-IP is routing to a ServiceNow cloud instance. This is low impact for cloud-hosted SNow but confirms BIG-IP is present.

---

### [F3] carrier.vintedgo.com — Internal Tracking API Endpoint Discovered
**Target**: https://carrier.vintedgo.com/public/v3/tracking_events
**Severity estimate**: P2 (if unauthenticated access to parcel data)
**Type**: Potential IDOR / Unauthenticated Data Access
**Source**: Leaked from VintedGo Next.js RSC (React Server Component) payload

**Evidence from page source:**
```javascript
"trackingUrl": "https://carrier.vintedgo.com/public/v3/tracking_events"
```

**Carrier root page** serves a minimal HTML page with Vinted Go branding — it's a live service.

**Why this matters:** The `/public/` prefix suggests intentionally public-facing, but:
- Can you query ANY tracking number without authentication?
- Do tracking events include sender/receiver address?
- Can you enumerate sequential tracking numbers?

**Manual test required** — needs a real VintedGo tracking number from a test shipment:
```bash
# With real tracking number from test shipment:
curl "https://carrier.vintedgo.com/public/v3/tracking_events/{real_tracking_number}"
```

---

### [F4] badger.it.vinted.com — Yopass Publicly Accessible, Non-Expiring Secrets Possible
**Target**: https://badger.it.vinted.com
**Severity estimate**: P3 (by itself) → P1 if secrets contain credentials
**Type**: Sensitive Data Exposure Risk

**Confirmed:**
- Public deployment of Yopass (open-source one-time secret sharing tool)
- No authentication required to access the service
- Config: `FORCE_ONETIME_SECRETS: false` — staff can create reusable/non-expiring secrets
- Config: `PREFETCH_SECRET: true` — ciphertext delivered to browser before passphrase entry
- All secrets require PGP encryption (client-side) before upload
- API path: `/create/secret` (requires PGP-encrypted payload)
- Health: `/health` → `{"status":"healthy"}`

**Risk:** If any Vinted employee has shared a secret (SSH key, API key, DB password) 
via badger.it.vinted.com and the UUID was leaked (Slack, email, git, logs), 
an attacker can retrieve it. The service is publicly accessible to anyone.

**Check:** Search GitHub, Wayback Machine, and any public Vinted code for `badger.it.vinted.com` URLs.

---

## 🟡 MEDIUM PRIORITY — Confirmed Surface, Needs Authenticated Test

### [F5] JWT app_id & scope Manipulation Surface
**Target**: www.vinted.com
**Severity estimate**: P2 if server-side validation bypassed
**Evidence from live token:**
```json
{"app_id": 4, "aud": "fr.core.api.vinted.com", "scope": "public"}
```
- `app_id: 4` — test app_id=1,2,3,5 after authenticating (different app = different permissions?)
- `scope: public` → test scope escalation after auth
- `aud: fr.core.api.vinted.com` — internal API hostname leaked in JWT

### [F6] VintedGo — Missing 5 Security Headers (Security Score: 70/100)
**Target**: www.vintedgo.com
**Not standalone reportable** — context only
Missing: CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, HSTS
→ Only relevant if chained with XSS/clickjacking PoC

### [F7] www.vinted.com — Missing CSP + HSTS (Security Score: 85/100)  
**Target**: www.vinted.com
**Not standalone reportable** — context only
→ Report only as part of XSS exploit chain

---

## 🟢 INFORMATIONAL — New Subdomains Discovered

| Subdomain | Status | Notes |
|---|---|---|
| `carrier.vintedgo.com` | 200 OK | Parcel tracking API — NOT in scope list but Vinted-owned |
| `routes.vintedgo.com` | Accessible | Route planning service |
| `cdn.vintedgo.com` | CDN | Asset delivery |
| `logistics.vintedgo.com` | Accessible | Business logistics portal |
| `fr.core.api.vinted.com` | Unknown | Internal API — in JWT `aud` field |
| `metrics-ingress-web.svc.vinted.com` | Unknown | K8s `.svc.` subdomain in network traffic |
| `metrics.vinted.lt` | Unknown | Lithuanian datacenter metrics collector |
| `press-center-static.vinted.com` | 200 OK | Static press resources (PDF served) |

Per Bugcrowd rules: "If you identify a security vulnerability on a target not in scope 
but demonstrably belonging to Vinted, you can report it."

---

## ⚡ NEXT MANUAL STEPS (Priority Order)

### Step 1 — ServiceNow Case IDOR (test-escalations.vintedgo.com)
1. Register account at `/csm?id=csm_registration`  
2. Submit a test case with parcel issue
3. Note your case number (format: `CS-XXXXXXX`)
4. Try accessing adjacent case IDs via the portal
5. Check if cases contain real customer personal data

### Step 2 — carrier.vintedgo.com Tracking IDOR
1. Create a real VintedGo test shipment (buy postage label)
2. Get tracking number from confirmation
3. Test `carrier.vintedgo.com/public/v3/tracking_events/{tracking_number}`
4. Check if response includes sender/receiver address
5. Try adjacent tracking numbers

### Step 3 — IDOR on www.vinted.com (Needs 2 test accounts)
1. Account A: list item → buy as Account B → note all IDs
2. From Account C: attempt to access shipment/transaction/address IDs
3. Focus on numeric increment/decrement from known IDs

### Step 4 — Race Condition on Wallet
1. Load wallet with test funds
2. Turbo Intruder: 50 concurrent purchase requests
3. Check for negative balance or double-item delivery

### Step 5 — Stored XSS
1. Create listing with XSS payloads in title/description
2. Set up webhook receiver
3. View listing from second account, check if webhook fires

---

## 📁 Files Saved
```
/home/abarnesh/Repos-clone/Bug_bounty/vinted/
├── reports/
│   ├── vinted_master_report.md          ← Full strategy + attack vectors
│   └── findings_summary.md              ← THIS FILE: confirmed findings
└── findings/
    └── critical_findings.md             ← Raw tool output + technical details
```
