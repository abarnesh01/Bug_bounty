# 🚨 CRITICAL FINDINGS — Vinted Bug Bounty
Generated: 2026-10-14 07:50 IST

---

## FINDING 1: badger.it.vinted.com = YOPASS (Secret Sharing Service)
**Severity**: P2–P3 (depends on access control)
**Target**: https://badger.it.vinted.com
**Status**: CONFIRMED VIA LIVE INSPECTION

### What It Is
`badger.it.vinted.com` is a public instance of **Yopass** — an open-source one-time 
secret sharing tool (https://github.com/jhaals/yopass). It is NOT a custom encryption 
service, but Vinted's internal deployment of Yopass for securely sharing secrets.

### Live Evidence
- Page title: "Yopass: Share Secrets Securely"
- Author link: https://github.com/jhaals (Johan Haals — Yopass creator)
- Upload endpoint: https://badger.it.vinted.com/#/upload
- Config endpoint: https://badger.it.vinted.com/config (returns JSON, HTTP 200)
- Form parameters: expiration (1h/24h/7d), oneTime (checkbox), generateKey (checkbox)

### Security Headers on badger.it.vinted.com (GOOD — well hardened)
- CSP: `default-src 'self'; script-src 'self'` (strict)
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Strict-Transport-Security: max-age=31536000
- Referrer-Policy: no-referrer
- X-XSS-Protection: 1; mode=block

### Attack Angles
1. **Config endpoint**: GET /config returns JSON — check for sensitive configuration leak
   ```
   curl -s https://badger.it.vinted.com/config | jq .
   ```
2. **Secret enumeration**: Yopass secrets are stored with UUIDs. If UUID generation 
   is predictable, secrets can be enumerated. Test:
   ```
   POST /secret with {"message": "test", "expiration": 3600, "one_time": true}
   GET /secret/{uuid} — try sequential/guessable UUIDs
   ```
3. **Access control**: Is this Yopass instance public or internal-only?
   - If INTERNAL secrets (passwords, API keys, SSH keys) are shared here and 
     the instance is internet-accessible without auth → P1
   - No authentication required to create/retrieve secrets (by design for Yopass)
   - Check if secrets set to NOT one-time can be read repeatedly
4. **Rate limiting**: No rate limiting on secret retrieval? Brute force UUID space
5. **CSP bypass**: Cloudflare beacon blocked by CSP (`script-src 'self'`) — 
   console error confirms strict CSP is enforced. Good hardening, but check edge cases.

### Next Steps
- [ ] `curl https://badger.it.vinted.com/config` — review configuration
- [ ] POST a test secret, note UUID format, check predictability
- [ ] Try retrieving a non-existent UUID — check error messages
- [ ] Check /api/ endpoints: `/api/secret`, `/api/v1/`
- [ ] Verify: is this accessible only from internal Vinted network or truly public?
  - If public + no auth + used for real credential sharing = SIGNIFICANT finding

---

## FINDING 2: test-escalations.vintedgo.com = ServiceNow CSP Portal
**Severity**: P2 (sensitive internal tool exposed)
**Target**: https://test-escalations.vintedgo.com
**Status**: CONFIRMED VIA LIVE INSPECTION

### What It Is
`test-escalations.vintedgo.com` is **ServiceNow Customer Service Management (CSM)** 
portal — Vinted Go's customer support escalation system. This is NOT a custom Angular 
app as suggested by scope listing, but a **ServiceNow** instance.

### Live Evidence
- Page title: "Customer Service Portal - Customer Support"
- Cookies set:
  - `glide_user_route` = glide.1bb6ae8220e4aad39cf28c5cf4d061ed (ServiceNow Glide)
  - `JSESSIONID` = [REDACTED — session ID]
  - `BIGipServerpool_testsupportvintedgo` = [REDACTED — BIG-IP cookie] (F5 BIG-IP LB!)
  - `glide_node_id_for_js` = [REDACTED — node fingerprint]...
- Server header: `snow_adc` (ServiceNow Application Delivery Controller)
- Script version: `v=10-06-2026_0230` (October 6, 2026 build)

### Exposed JavaScript Globals (Inline Scripts — HIGH VALUE)
```javascript
// Session data exposed in page source:
window.NOW.session_id = '[REDACTED]';
window.NOW.user_name = 'guest';
window.NOW.user_id = '[REDACTED]';
window.NOW.user_display_name = 'Guest';
window.g_ck = '[REDACTED — CSRF token]';
window.NOW.portal_id = '[REDACTED]';
window.NOW.instance_id = '64c13c2bdb7bd5d02f68c5970...';
window.NOW.user_id_hashed = '[REDACTED]';
```

**`window.g_ck`** is the **ServiceNow CSRF/session token** (`glide_ck`) — this is 
critical! This token is required for authenticated ServiceNow API calls.

### F5 BIG-IP Load Balancer Cookie
`BIGipServerpool_[pool-name] = [REDACTED — BIG-IP cookie hex]`
This can be decoded to reveal internal server IP/port. BIG-IP cookie format:
`{pool_id}.{encoded_server_ip}.{encoded_port}`
→ Decode to find internal backend server IP.

### Portal Configuration Leaked
```json
{
  "sys_id": "[REDACTED — portal sys_id]",
  "title": "Customer Support",
  "sc_catalog": "[REDACTED — catalog sys_id]",
  "theme": "Vinted Customer Portal",
  "sp_chat_queue": "4bc7a3f3c3133100..."
}
```

### Attack Angles

#### A. ServiceNow Guest API Access (HIGH PRIORITY — P2)
ServiceNow CSP portals often expose REST APIs accessible to guest users:
```
GET /api/now/table/sn_customerservice_case     ← access all support cases?
GET /api/now/table/incident                    ← incident records
GET /api/now/table/sys_user                    ← user records  
GET /api/now/table/sn_customerservice_account  ← customer accounts
```
With `window.g_ck` as the CSRF token and `JSESSIONID` as session:
```bash
curl -H "X-UserToken: 61655dabc37f8310535d1723e40131ea..." \
     -b "JSESSIONID=[REDACTED — session ID]" \
     "https://test-escalations.vintedgo.com/api/now/table/sn_customerservice_case"
```

#### B. BIG-IP Cookie Decode — Internal IP Disclosure
```python
import struct, socket
cookie = "2041356f27f044656ab17e11cb77f7df"
# Decode BIG-IP persistence cookie to get internal server IP
```

#### C. ServiceNow IDOR via sys_id
ServiceNow records are identified by `sys_id` (UUID). All sys_ids exposed in page source.
Test direct table access:
```
GET /api/now/table/sn_customerservice_case/{sys_id}
GET /api/now/table/sp_portal/[REDACTED-SYS_ID_RAW-e25b306b]
```

#### D. Knowledge Base — Unauthenticated Access
```
GET /csm?id=kb_category   ← Knowledge base visible to guest?
GET /csm?id=kb_article&sys_id=...  ← Direct article access
```

#### E. Case Creation as Guest
Link found: `/csm?id=sc_category&sys_id=6b0a05401be82110a069866ee54bcb50`
"New case - Do you have an issue with your parcel? Let us know!"
→ Can guests create support cases on behalf of Vinted Go customers?

### Next Steps
- [ ] Decode BIG-IP cookie → internal IP/port
- [ ] Test ServiceNow REST API as guest with g_ck token
- [ ] Enumerate support cases via `/api/now/table/sn_customerservice_case`
- [ ] Check if case creation exposes real customer data
- [ ] Test `/api/now/table/sys_user` for user enumeration

---

## FINDING 3: VintedGo — Google Maps API Key Exposed
**Severity**: OUT OF SCOPE per program rules ("Disclosed or misconfigured Google Maps API keys")
**Target**: https://www.vintedgo.com
**Status**: NOTED (not reportable)

```
[REDACTED — Google Maps API key]
```
Found in: `https://maps.googleapis.com/maps/api/js?libraries=marker,places,geometry&key=AIzaSy...`
→ Excluded per Vinted's scope rules. Note for completeness.

---

## FINDING 4: VintedGo — Tracking Number Input + Location Search
**Severity**: P3 (potential IDOR/info disclosure)
**Target**: https://www.vintedgo.com
**Status**: REQUIRES MANUAL TESTING

### Evidence
VintedGo homepage has two inputs:
1. `trackingNumber` — "par ex. 100000000023" (tracking number format: numeric, ~12 digits)
2. Address search — "par ex. 22, rue de Toure" (carrier location finder)

### Tracking endpoint:
```
GET /fr/tracking?country=fr&region=europe
POST with trackingNumber=100000000023
```

### Attack vector:
- Do tracking numbers expose sender/receiver address to unauthenticated users?
- Sequential tracking numbers? Enumerate to find active parcels?
- Does `/fr/tracking` require authentication or is it open?

### Additional Discovered Endpoints:
```
/fr/carrier-locations?country=fr&region=europe  ← carrier/relay point map
/fr/tracking?country=fr&region=europe           ← parcel tracking  
/fr/become-a-partner?country=fr&region=europe   ← partner portal
/fr/become-a-partner/apply?type=VLocker         ← VLocker application
/fr/privacy-policy                              ← policy
/fr/terms-and-conditions                        ← ToS
https://logistics.vintedgo.com/                 ← Business logistics (NOT in scope)
https://routes.vintedgo.com/                    ← Route planning (NOT in scope)
```

---

## FINDING 5: VintedGo — New Subdomains Discovered (Not in Scope)
**Severity**: Informational — for awareness only
**Note**: These are OUT OF SCOPE but demonstrably Vinted-owned.

```
logistics.vintedgo.com  ← "Logistique pour les entreprises" — business logistics
routes.vintedgo.com     ← "Expédier un colis" — shipping routes
cdn.vintedgo.com        ← CDN (fonts, assets)
press-center-static.vinted.com ← Press resources (PDF served)
```

Per program rules: "If you happen to identify a security vulnerability on a target 
that is not in scope but it demonstrably belongs to Vinted, you can report it."
→ Report if any of these have obvious vulnerabilities.

---

## FINDING 6: VintedGo — Missing Security Headers (Context Only)
**Severity**: Not standalone reportable
**Target**: www.vintedgo.com (security score: 70/100)

Missing on VintedGo:
- Content-Security-Policy
- X-Frame-Options  
- X-Content-Type-Options
- Referrer-Policy
- Strict-Transport-Security (on main page, present on CDN assets)

Note: These are 5 missing headers vs. 2 on www.vinted.com. VintedGo has worse posture.
Only relevant if chained with XSS or clickjacking proof.

---

## SUMMARY TABLE

| # | Finding | Target | Severity | Status |
|---|---------|--------|----------|--------|
| 1 | Yopass secret-sharing service — public deployment, no auth | badger.it.vinted.com | P2-P3 | Manual testing needed |
| 2 | ServiceNow CSP — guest API access via g_ck token | test-escalations.vintedgo.com | P2 | Manual testing needed |
| 3 | BIG-IP cookie reveals internal backend IP | test-escalations.vintedgo.com | P3 | Decode + verify |
| 4 | ServiceNow sys_id leakage in page source | test-escalations.vintedgo.com | P3 | Test IDOR |
| 5 | VintedGo tracking — potential unauthenticated tracking | www.vintedgo.com | P3 | Manual test |
| 6 | Google Maps API key exposed | www.vintedgo.com | Out of scope | Noted |
| 7 | New subdomains: logistics.vintedgo.com, routes.vintedgo.com | Out of scope | Info | Report if vuln found |

---

## FINDING 7: carrier.vintedgo.com — Internal Tracking API Discovered
**Severity**: P2–P3 (IDOR potential — unauthenticated tracking events exposure)
**Target**: https://carrier.vintedgo.com
**Status**: REQUIRES MANUAL TESTING WITH REAL TRACKING NUMBERS
**Source**: Exposed in VintedGo Next.js page source code

### Evidence
Found in tracking page RSC payload:
```
"trackingUrl": "https://carrier.vintedgo.com/public/v3/tracking_events"
```

### Description
`carrier.vintedgo.com` is VintedGo's internal carrier/logistics API, exposed via the 
public tracking page. The `/public/v3/tracking_events` endpoint is the data source for 
the VintedGo parcel tracker.

### Attack Angles
1. **Unauthenticated access**: Does /public/v3/tracking_events require auth?
   - Tested: 404 on enumerated routes — need real tracking number format
   - Tracking number format from UI placeholder: `100000000023` (12 digits)
   
2. **IDOR via tracking number**: If tracking events are returned without auth,
   an attacker can track ANY parcel (not just their own), potentially learning:
   - Delivery address (where a person lives)
   - Sender address
   - Parcel status and movement history
   
3. **Sender/receiver exposure**: Delivery tracking typically reveals:
   - Recipient's name and address
   - Sender's name (or at least city/region)
   
### Next Steps (requires test parcel with VintedGo)
```bash
# After creating a real test shipment through VintedGo:
curl "https://carrier.vintedgo.com/public/v3/tracking_events/{tracking_number}"
curl "https://carrier.vintedgo.com/public/v3/tracking_events?tracking_number={N}"

# Try numeric enumeration around known tracking number
# e.g., if you get tracking number 100000012345, try 100000012344, 100000012346
```

### Additional URLs Found in Source
- `https://cdn.vintedgo.com` — VintedGo CDN
- `https://routes.vintedgo.com/fr` — Route planning (separate subdomain)
- `https://careers.vinted.com/jobs` — Jobs portal

---

## FINDING 8: Yopass Requires PGP Encryption — Configuration Analysis
**Severity**: P3 (configuration review)
**Target**: https://badger.it.vinted.com
**Status**: Confirmed

### Config Response
```json
{
  "DEFAULT_EXPIRY": 3600,
  "DISABLE_FEATURES": false,
  "DISABLE_UPLOAD": false,
  "FORCE_ONETIME_SECRETS": false,
  "NO_LANGUAGE_SWITCHER": false,
  "PREFETCH_SECRET": true,
  "READ_ONLY": false
}
```

### Key Observations
1. **FORCE_ONETIME_SECRETS = false**: Secrets can be set to non-one-time.
   If staff create non-expiring, reusable secrets (not forcing one-time), 
   and an attacker discovers the UUID, they can repeatedly read it.
   
2. **PREFETCH_SECRET = true**: Secret content is pre-fetched in browser.
   This means the ciphertext is delivered to the browser even before 
   the passphrase is entered. Risk: timing/cache attacks on delivery.
   
3. **Secret API Requires PGP**: All secrets must be PGP-encrypted client-side.
   `{"message": "Message must be PGP encrypted"}` — so raw plaintext injection blocked.
   
4. **DISABLE_UPLOAD = false**: File uploads enabled. Any file type?
   Check if large file uploads are rate-limited to prevent abuse.
   
5. **READ_ONLY = false**: Full create + read in both directions.

### Risk Scenario
If Vinted engineering staff use `badger.it.vinted.com` to share:
- Database passwords
- API keys  
- SSH private keys
- JWT signing keys

...and the Yopass instance is publicly accessible (confirmed: no auth wall), 
then leaked UUIDs from Slack/email/code = direct credential exposure.

The UUID format from Yopass is standard v4 UUID (128-bit random).
Brute-force is infeasible. But UUID leakage via:
- Git history
- Slack/Teams logs  
- Bug tracker tickets
- Wayback Machine cache
- Log files
...is realistic.

### Test
Check if Vinted's public GitHub repositories contain any badger.it.vinted.com URLs:
```bash
# Search GitHub for leaked Yopass UUIDs
# Search format: site:github.com "badger.it.vinted.com"
# Search Wayback: web.archive.org/web/*/badger.it.vinted.com/*
```

