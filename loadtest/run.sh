#!/usr/bin/env bash
# Load test that triggers HPA scale-up on the nginx-demo Deployment.
#
# Usage:
#   ./run.sh                                     # default 60s, 50 concurrent
#   ./run.sh -z 2m -c 100                        # custom duration / concurrency
#   HOST=http://app.X.nip.io ./run.sh            # override the target URL
#
# In another terminal, watch HPA react:
#   kubectl get hpa nginx-demo -n nginx-demo -w
#   kubectl get pods -n nginx-demo -w
set -euo pipefail

if ! command -v hey >/dev/null 2>&1; then
  echo "Install 'hey' first: brew install hey   (or https://github.com/rakyll/hey)" >&2
  exit 1
fi

HOST="${HOST:-http://app.98-84-34-207.nip.io}"
DURATION="${DURATION:--z 60s}"
CONCURRENCY="${CONCURRENCY:--c 50}"

echo "==> Target: $HOST"
echo "==> Args:   $DURATION $CONCURRENCY $*"
echo

# shellcheck disable=SC2086
hey $DURATION $CONCURRENCY "$@" "$HOST"

cat <<'EOF'

==> Done. To see HPA scaling history:
    kubectl get hpa nginx-demo -n nginx-demo
    kubectl describe hpa nginx-demo -n nginx-demo | tail -20
EOF
