# Secrets Audit Report — Bug_bounty Repository
Date: 2026-10-14 | Status: AWAITING APPROVAL TO APPLY

---

## Audit Scope

- All files tracked by git: 13 files across 4 directories
- All git commits: 6 commits (earliest: a37eba5, latest: 8090ec0)
- Scan patterns: hex tokens ≥40 chars, JWT format, cookie name=value, Google API key prefix, emails, IP addresses

---

## Findings Summary

| # | File | Line(s) | Type | Risk | Action |
|---|---|---|---|---|---|
| S1 | `vinted/findings/critical_findings.md` | 77 | JSESSIONID value | Session fixation risk if live | Replace with [REDACTED] |
| S2 | `vinted/findings/critical_findings.md` | 77 | BIGipServerpool cookie value | Low (public IP decoded) | Replace with [REDACTED] |
| S3 | `vinted/findings/critical_findings.md` | 77 | glide_node_id_for_js value | Low (node fingerprint) | Replace with [REDACTED] |
| S4 | `vinted/findings/critical_findings.md` | 84 | window.NOW.session_id value | Low (guest session) | Replace with [REDACTED] |
| S5 | `vinted/findings/critical_findings.md` | 88 | window.g_ck value | Medium — CSRF token | Replace with [REDACTED] |
| S6 | `vinted/findings/critical_findings.md` | 88 | window.NOW.user_id / portal_id values | Low (ServiceNow guest sys_id) | Replace with [REDACTED] |
| S7 | `vinted/findings/critical_findings.md` | 91 | window.NOW.user_id_hashed value | Low (guest hash, public) | Replace with [REDACTED] |
| S8 | `vinted/findings/critical_findings.md` | 172 | Google Maps API key | **HIGH — live key, in-scope exclusion is Vinted's but key is yours too** | Replace + rotate |
| S9 | `vinted/proof/f1_servicenow/proof.txt` | 12–13 | g_ck + session_id values | Medium (ephemeral tokens) | Replace with [REDACTED] |
| S10 | `vinted/proof/f1_servicenow/proof.txt` | 15,17,20 | user_id, instance_id, node fingerprint | Low | Replace with [REDACTED] |
| S11 | `vinted/proof/f1_servicenow/proof.txt` | 22–23 | glide_user_route + BIGip cookie values | Low | Replace with [REDACTED] |
| S12 | `vinted/reports/findings_summary.md` | 20,23 | g_ck + session tokens in code block | Medium | Replace with [REDACTED] |
| S13 | `vinted/reports/findings_summary.md` | 52 | BIGipServerpool cookie value | Low | Replace with [REDACTED] |
| S14 | `vinted/reports/findings_summary.md` | 56,59 | Decoded IP address | Low (public IP) | Replace with [REDACTED] |
| S15 | `vinted/proof/f2_bigip/bigip_decode.txt` | 8 | Raw BIG-IP cookie hex | Low | Replace with [REDACTED] |
| S16 | `vinted/proof/f2_bigip/bigip_decode.txt` | 11,14 | Decoded IP address | Low (public IP) | Replace with [REDACTED] |
| S17 | `vinted/reports/rigorous_analysis.md` | 69,70,182 | Decoded IP address in analysis text | Low | Replace with [REDACTED] |

---

## Risk Assessment by Item

### S8 — Google Maps API Key (HIGHEST PRIORITY)

**Type**: Google Maps JavaScript API key (AIzaSy… prefix)  
**Location**: `vinted/findings/critical_findings.md` line 172  
**History**: First introduced in commit `87c7103` — present since then  
**Risk**: This key is live. Even though it belongs to *Vinted* (observed in their page), it is committed verbatim in your repository. If your repo is public or forks exist, this is a discoverable credential in git history.  
**Note**: The program explicitly excludes this from *Vinted's* scope ("Disclosed Google Maps API keys"), but you have no obligation to store it.

**Immediate action (before any commit)**: Delete from your local files. Do not rotate — you do not control this key; it belongs to Vinted. If the key appears to be restricted to Vinted's domains, no action needed on your end beyond removing it from your notes.

---

### S5, S9, S12 — g_ck / CSRF Token Values (MEDIUM)

**Type**: ServiceNow `glide_ck` CSRF token  
**Risk**: These tokens are ephemeral and session-scoped. The specific values captured are almost certainly already expired (sessions are typically 30–60 minutes on ServiceNow). **No live risk** from the specific values stored, but the pattern of storing CSRF tokens in committed files creates a process risk.  
**Action**: Replace with `[REDACTED — CSRF token, ephemeral]` in sanitized files.

---

### S1, S4, S10–S11 — Session IDs and Cookie Values (LOW)

**Type**: JSESSIONID, glide_user_route, glide_node_id_for_js  
**Risk**: Guest session values — scoped to an anonymous session that has no privileges. Almost certainly expired. No meaningful live risk.  
**Action**: Replace with [REDACTED] for hygiene.

---

### S2, S13–S17 — BIG-IP Cookie + Decoded IP (LOW)

**Type**: BIG-IP persistence cookie raw hex + decoded public IP  
**Risk**: The decoded IP (`32.65.53.111`) is a public global address — confirmed in analysis to belong to ServiceNow's cloud infrastructure, not Vinted's internal network. No sensitive network topology exposed.  
**Action**: Replace for hygiene and to keep the report consistent with the rigorous_analysis.md conclusion.

---

### S6, S7, S10 — ServiceNow sys_id / user_id Values (LOW)

**Type**: ServiceNow UUIDs for guest user records  
**Risk**: These are the fixed UUIDs for ServiceNow's built-in anonymous guest account. They are the same across all ServiceNow instances — publicly known. No risk.  
**Action**: Replace for hygiene only.

---

## Git History Assessment

| Commit | Secret type in diff | Status |
|---|---|---|
| `87c7103` | Hex blobs (session tokens, cookies), Google API key | ⚠ Introduced all secrets |
| `8090ec0` | No new secrets | Clean |
| All others | No secrets found | Clean |

**All secrets originate from a single commit (`87c7103`).** This means git history rewrite
(interactive rebase or BFG Repo Cleaner) would remove them with one operation.

---

## Files NOT requiring changes

| File | Reason |
|---|---|
| `vinted/proof/f3_carrier/proof.txt` | No tokens, IPs, or keys |
| `vinted/proof/f4_yopass/proof.txt` | No tokens — config values only (public) |
| `vinted/proof/f5_jwt/jwt_decode.txt` | JWT header/payload only — no signature, no private data |
| `vinted/reports/vinted_master_report.md` | Email found is `attacker.com` (example payload, not real PII) |
| `Zerodha Bug Bounty Program/*` | No secrets found |
| `HostGator LATAM Bug Bounty/*` | No secrets found |

---

## Sanitized Files Ready

Sanitized replacements are staged at `/tmp/vinted_sanitized/`.  
To apply them, run the commands in `APPLY_SANITIZATION.sh` (awaiting your approval).

---

## Remediation Steps — Exact Commands (DO NOT RUN until approved)

See `APPLY_SANITIZATION.sh` for the full apply script.

After applying file changes, the recommended git remediation is:

### Option A — Amend and force-push (simplest, works if no collaborators)
Requires approval. Rewrites commit `87c7103`.

### Option B — BFG Repo Cleaner (thorough history purge)
Requires approval. Removes the specific strings from all commits.

### Option C — Accept history as-is, apply sanitization going forward
Appropriate if: repo is private, no collaborators, low-value tokens (all expired).
Only the Google Maps API key needs immediate attention regardless of which option is chosen.

