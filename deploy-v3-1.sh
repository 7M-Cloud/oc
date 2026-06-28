#!/bin/bash
#
# ACM Fleet Unified Observability v3.1 - Automated Deployment Script
# Usage: ./deploy-v3-1.sh
#

set -e

NS="open-cluster-management-observability"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

echo "================================================"
echo "  ACM Fleet Unified Observability v3.1"
echo "  Automated Deployment Script"
echo "================================================"
echo ""

echo "🔍 Step 0/6 - Verifying prerequisites..."
oc whoami --show-server || { echo "❌ Not logged in to OpenShift"; exit 1; }

if ! oc get ns "$NS" >/dev/null 2>&1; then
    echo "❌ Namespace $NS not found - is ACM Observability enabled?"
    exit 1
fi

if ! oc get deploy observability-grafana -n "$NS" >/dev/null 2>&1; then
    echo "❌ observability-grafana deployment not found"
    exit 1
fi

echo "✅ Prerequisites OK"
echo ""

echo "📡 Step 1/6 - Applying metrics allowlist..."
oc apply -f observability-metrics-custom-allowlist-v3.yaml
echo "✅ Allowlist applied"
echo ""

echo "⏳ Step 2/6 - Waiting 90s for metric propagation to managed clusters..."
sleep 90
echo "✅ Wait complete"
echo ""

echo "📊 Step 3/6 - Deploying v3.1 dashboard (server-side apply)..."
oc apply -f acm-fleet-unified-observability-v3-1.yaml \
  --server-side=true --force-conflicts
echo "✅ Dashboard ConfigMap applied"
echo ""

echo "✅ Step 4/6 - Verifying ConfigMap..."
oc get cm acm-fleet-unified-observability-v3-1 -n "$NS"
LABEL=$(oc get cm acm-fleet-unified-observability-v3-1 -n "$NS" \
  -o jsonpath='{.metadata.labels.grafana-custom-dashboard}')
if [ "$LABEL" != "true" ]; then
    echo "⚠️ grafana-custom-dashboard label not set correctly!"
    exit 1
fi
echo "✅ Auto-injection label verified"
echo ""

echo "🔍 Step 5/6 - Checking Grafana dashboard loader (waiting 15s)..."
sleep 15
LOG=$(oc logs -n "$NS" deploy/observability-grafana \
  -c grafana-dashboard-loader --tail=50 | grep -i "v3-1" || true)
if [ -n "$LOG" ]; then
    echo "✅ Loader picked up dashboard:"
    echo "$LOG"
else
    echo "⚠️ Dashboard not yet visible in loader logs."
    echo "   Try restarting Grafana:"
    echo "   oc rollout restart deploy/observability-grafana -n $NS"
fi
echo ""

echo "🌐 Step 6/6 - Grafana URL:"
URL="https://$(oc get route grafana -n "$NS" -o jsonpath='{.spec.host}')"
echo "$URL"
echo ""
echo "📍 Navigate to: Dashboards → Browse → General →"
echo "   ACM Fleet - Unified Observability v3.1 (Reordered + Drill-down)"
echo ""
echo "================================================"
echo "  ✅ v3.1 deployment complete!"
echo "================================================"
