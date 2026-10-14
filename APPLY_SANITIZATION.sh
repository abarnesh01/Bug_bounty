#!/usr/bin/env bash
# APPLY_SANITIZATION.sh
# Copies sanitized files over originals.
# Does NOT commit, push, or rewrite git history.
# Run only after reviewing the proposed diff and approving.
set -euo pipefail

REPO="/home/abarnesh/Repos-clone/Bug_bounty"
STAGING="/tmp/vinted_sanitized"

echo "[1/5] Applying: vinted/findings/critical_findings.md"
cp "$STAGING/findings/critical_findings.md" \
   "$REPO/vinted/findings/critical_findings.md"

echo "[2/5] Applying: vinted/proof/f1_servicenow/proof.txt"
cp "$STAGING/proof/f1_servicenow/proof.txt" \
   "$REPO/vinted/proof/f1_servicenow/proof.txt"

echo "[3/5] Applying: vinted/proof/f2_bigip/bigip_decode.txt"
cp "$STAGING/proof/f2_bigip/bigip_decode.txt" \
   "$REPO/vinted/proof/f2_bigip/bigip_decode.txt"

echo "[4/5] Applying: vinted/reports/findings_summary.md"
cp "$STAGING/reports/findings_summary.md" \
   "$REPO/vinted/reports/findings_summary.md"

echo "[5/5] Applying: vinted/reports/rigorous_analysis.md"
cp "$STAGING/reports/rigorous_analysis.md" \
   "$REPO/vinted/reports/rigorous_analysis.md"

echo ""
echo "Done. Working tree updated. No git operations performed."
echo ""
echo "Next steps (your decision — see SECRETS_AUDIT.md):"
echo "  git diff                          # review all changes"
echo "  git add -p                        # stage selectively"
echo "  git commit -m 'chore: redact session tokens and API key from proof files'"
echo ""
echo "To also purge git history (Option B):"
echo "  # Install BFG: https://rtyley.github.io/bfg-repo-cleaner/"
echo "  # bfg --replace-text replacements.txt $REPO/.git"
echo "  # git reflog expire --expire=now --all"
echo "  # git gc --prune=now --aggressive"
echo "  # git push --force-with-lease"
