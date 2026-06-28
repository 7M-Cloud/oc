# ACM Fleet - Unified Observability v3.1

**Single-pane-of-glass Grafana dashboard for Red Hat ACM Observability**

Capacity • Overcommitment • Action Items • One-level Drill-down — aligned with CNCF & Red Hat best practices.

---

## 📦 Bundle Contents

| File | Purpose |
|---|---|
| `acm-fleet-unified-observability-v3-1.yaml` | ConfigMap with embedded Grafana dashboard JSON. Apply with `oc apply`. |
| `acm-fleet-unified-observability-v3-1-dashboard.json` | Standalone dashboard JSON for manual import via Grafana UI. |
| `observability-metrics-custom-allowlist-v3.yaml` | ACM metrics allowlist. Adds required metrics + recording rules. |
| `deploy-v3-1.sh` | Automated end-to-end deployment script. |
| `README.md` | This file. |

---

## 🎯 Dashboard Features

- **11 organized rows** covering availability, action items, operators, namespace, pod, alerts, vCPU, memory, storage, network
- **93 data panels** + 7 markdown panels
- **128 PromQL queries** with cluster/namespace/pod scoping
- **8 dashboard variables**: datasource, cluster, workload_scope, namespace, node, pod, interval, severity
- **Workload Scope toggle**: Platform / Application / All namespaces
- **One-level drill-down on every panel** (100% coverage)
- **Action Items section** with CNCF & Red Hat best-practice violations
- **Clean column headers** in all tables (no `Value #A` artifacts)

---

## 📊 Row Structure

```
📊 Row 0  — Information Header
📈 Row 1  — Executive Summary (6 KPI tiles)
🚨 Row 2  — Action Items & Recommendations (CNCF + Red Hat)
🌐 Row 3  — Fleet Availability + Top 5 Stressed Clusters
⚙️  Row 4  — Operators + etcd + API Server Health
📋 Row 5  — Namespace Workload Table (17 clean columns)
🚨 Row 6  — Pod Health & Drill-down
🔔 Row 7  — Active Alerts
🧮 Row 8  — vCPU (6 stats + 4 gauges + trend + top namespaces)
🧠 Row 9  — Memory (same structure as CPU)
💾 Row 10 — Storage (PVC + Disk + IOPS)
🌐 Row 11 — Network (RX/TX + drops + top namespaces/pods)
```

---

## ✅ Prerequisites

- Red Hat ACM 2.x hub cluster
- ACM Observability (MCO) enabled
- `oc` CLI logged in to the hub
- Cluster admin or `open-cluster-management-observability` namespace edit permissions

Verify:
```bash
oc whoami --show-server
oc get MultiClusterHub -A
oc get MultiClusterObservability -A
oc get deploy observability-grafana -n open-cluster-management-observability
```

---

## 🚀 Deployment (Quick Start)

### Option A — Automated script

```bash
chmod +x deploy-v3-1.sh
./deploy-v3-1.sh
```

### Option B — Manual steps

```bash
# Step 1: Apply metrics allowlist FIRST
oc apply -f observability-metrics-custom-allowlist-v3.yaml

# Step 2: Wait for metric propagation
sleep 90

# Step 3: Apply the dashboard ConfigMap (server-side apply REQUIRED — JSON > 256KB annotation limit)
oc apply -f acm-fleet-unified-observability-v3-1.yaml \
  --server-side=true --force-conflicts

# Step 4: Verify ConfigMap
oc get cm acm-fleet-unified-observability-v3-1 \
  -n open-cluster-management-observability

# Step 5: Verify Grafana loader picked it up
oc logs -n open-cluster-management-observability \
  deploy/observability-grafana \
  -c grafana-dashboard-loader \
  --tail=30 | grep -i v3-1

# Step 6: Get Grafana URL
echo "https://$(oc get route grafana -n open-cluster-management-observability -o jsonpath='{.spec.host}')"
```

Navigate in Grafana to:
```
Dashboards → Browse → General → ACM Fleet - Unified Observability v3.1 (Reordered + Drill-down)
```

---

## 🔍 Drill-down Behavior

| Where | Click Action |
|---|---|
| **Any panel** | Click 🔍 icon (top-left) → opens dashboard with current scope in new tab |
| **Top-5 cluster bar gauge** | Click any bar → drill to that cluster |
| **Top-N namespace bar gauge** | Click any bar → drill to that namespace |
| **Top-N pod bar gauge** | Click any bar → drill to that pod |
| **Namespace table** | Click "Namespace" column → drill to namespace |
| **Pod table** | Click "Pod" column → drill to pod |
| **Alerts table** | Click "Cluster" column → drill to cluster |

---

## 🎨 Dashboard Variables

| Variable | Purpose | Cascades from |
|---|---|---|
| `datasource` | Prometheus/Thanos datasource | (root) |
| `cluster` | One or all clusters (multi-value) | (root) |
| `workload_scope` | All / Platform / Application namespaces | (independent) |
| `namespace` | Within cluster + scope | cluster, workload_scope |
| `node` | Within cluster | cluster |
| `pod` | Within namespace | cluster, namespace |
| `interval` | Rate window (1m / 5m / 15m / 30m / 1h) | (independent) |
| `severity` | Alert severity filter | (independent) |

---

## 🚨 Action Items Categories

The Action Items section (Row 2) shows violations across 5 categories aligned with CNCF and Red Hat best practices:

| Category | Action Items |
|---|---|
| **🚨 Resource Hygiene** | Pods without CPU/Memory requests/limits |
| **🔧 Reliability** | Single replicas, CrashLoopBackOff, high restarts, ImagePullBackOff |
| **💾 Capacity** | CPU overcommit >150%, Memory overcommit >100%, PVCs >85%, Unbound PVCs |
| **⚙️ Platform Health** | Operators degraded, etcd DB >7GB, API p99 >1s, etcd leader changes |
| **📜 Governance** | Missing ResourceQuota / LimitRange / PDB, failed pods |

---

## 🛠️ Troubleshooting

### Dashboard doesn't appear in Grafana
```bash
oc rollout restart deploy/observability-grafana \
  -n open-cluster-management-observability
```

### "Request entity too large" error
Use server-side apply (always required for this dashboard):
```bash
oc apply -f acm-fleet-unified-observability-v3-1.yaml \
  --server-side=true --force-conflicts
```

### Panels show "No Data"
- Wait 5-10 minutes after applying the allowlist
- Verify metric flow:
```bash
oc -n open-cluster-management-observability \
  exec deploy/observability-thanos-query -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query=kube_resourcequota' | head
```

### Check loader logs
```bash
oc logs -n open-cluster-management-observability \
  deploy/observability-grafana \
  -c grafana-dashboard-loader | grep -i "error\|fail" | tail
```

---

## 🔁 Updating or Removing

### Update
```bash
oc apply -f acm-fleet-unified-observability-v3-1.yaml \
  --server-side=true --force-conflicts
```

### Remove
```bash
oc delete cm acm-fleet-unified-observability-v3-1 \
  -n open-cluster-management-observability
```

Auto-removes from Grafana within 30 seconds.

---

## 🌍 Multi-Hub Deployment

This dashboard is **100% ACM-agnostic**:
- No hardcoded cluster names
- Datasource as variable
- Stable UID `acm-fleet-unified-obs-v3-1`
- Can be deployed to any ACM 2.x hub with `oc apply`

For multiple hubs, deploy via:
- Manual `oc apply` per hub
- ArgoCD ApplicationSet
- ACM Policy + PlacementRule (GitOps governance pattern)

---

## 📚 Best Practices References

| Topic | Source | Guideline |
|---|---|---|
| Resource requests | CNCF | Every container MUST declare CPU & Memory requests |
| Memory limits | Red Hat OCP | Should equal request (Guaranteed QoS) |
| CPU overcommit | Red Hat sizing | OK up to 150% (CPU compressible) |
| Memory overcommit | Red Hat sizing | ≤ 100% (memory NOT compressible) |
| HA replicas | Red Hat OCP | Production: ≥2 replicas + PDB + topology spread |
| etcd DB size | Red Hat OCP | Hard limit 8GB; defrag at 7GB |
| API latency | Kubernetes SLO | p99 read <1s, write <5s |
| PVC capacity | Industry | Alert at 85%, expand at 90% |
| ResourceQuota | CNCF | Every app namespace needs one |

---

## 📝 Version

- **Version**: 3.1
- **Schema**: Grafana 39 (Grafana 10/11 compatible)
- **Tags**: acm, openshift, thanos, capacity, overcommit, action-items, best-practices, drilldown, v3.1

---

## 📧 Support

For issues or improvements, contact the Platform Engineering team.
