# HostGator LATAM Bug Bounty — Authenticated AI Agent / VPS Control Plane Gate (2026-09-22)

Scope note: This phase was limited to passive mapping of the authenticated customer control plane, using only a researcher-owned account if one existed. No bypasses, no password spraying, no destructive actions, and no service purchase or charge were attempted.

## 1) Objective and stop condition

The assessment goal was to investigate only the authenticated customer/VPS control plane for HostGator’s AI-related offerings, with a single researcher-owned account as the boundary.

This pass did not find any valid researcher-owned authenticated session or active purchased service in the current environment. Because the customer portal is not publicly discoverable as an accessible control-plane app without a valid account, the investigation reached the required stop condition:

- No active customer account/session was available in this environment.
- No purchased or trial VPS/AI service was available to test against.
- No authenticated control-plane routes could be meaningfully enumerated without a valid session.

The assessment therefore stops here and reports the limitation rather than proceeding into any unauthorized or speculative testing.

## 2) Passive host and portal discovery performed

### Public customer portal host
- https://cliente.hostgator.com.br/
- Response: HTTP 200
- Observed behavior: loads an app shell / landing shell for a customer portal, not a public user dashboard.

### Likely auth-related routes checked without a session
- https://cliente.hostgator.com.br/login
- https://cliente.hostgator.com.br/minha-conta
- https://cliente.hostgator.com.br/portal
- All returned HTTP 404 in the unauthenticated context.

This strongly suggests the customer portal is a protected SPA/React app behind a valid session, and its internal routes are not directly accessible to the public.

## 3) Evidence from the app shell

Stealth passive inspection of the portal shell showed:
- It is served as a static app shell.
- JS bundle references exist under /static/js/ and /static/css/.
- No direct embedded API URLs, auth endpoints, or service IDs were exposed in the HTML shell.
- Patterns matching api, auth, oauth, login, vps, openclaw, n8n, workflow, and server-related strings were not found in the public HTML shell.

This is consistent with an authenticated-only application that does not disclose internal route names or resource identifiers before login.

## 4) Notable auth-domain signal

A browser-level check showed a request being aborted to:
- https://financeiro.hostgator.com.br/api/v2/logout

This indicates the app is tied into a finance/auth domain and is session-aware, but it is not usable for the current assessment without a valid logged-in customer context.

## 5) Risk and scope boundary

The investigation remains within the approved constraints:
- No fake account creation
- No purchase flow
- No billing or charge generation
- No login bypass
- No account hijack or credential guessing
- No exploitation of session handling
- No unauthenticated API abuse

## 6) Conclusion

No authenticated AI Agent / VPS control-plane functionality could be mapped from this environment because there was no valid researcher-owned customer account or purchased service available to access the protected portal.

The public site does expose AI/VPS marketing content, but the real customer control plane is gated behind valid hosted-account access. Without that authenticated context, there is no safe, evidence-backed way to enumerate the internal AI/VPS management surface.

This is therefore a limitation report, not a vulnerability finding.
