[![CircleCI](https://circleci.com/gh/giantswarm/karpenter-app.svg?style=shield)](https://circleci.com/gh/giantswarm/karpenter-app)

# karpenter chart

Giant Swarm offers a `karpenter-bundle` Managed App which can be installed in workload clusters.
Here we define the `karpenter-bundle` and `karpenter` charts with their templates and default configuration.

## Key terminology

| Term | Where it lives | What it does |
|------|---------------|--------------|
| **BUNDLE-ONLY** | Management cluster only | Never forwarded to workload chart. Examples: `clusterID`, `region`, `ociRepositoryUrl`, `workersIamRole` |
| **UPSTREAM** | Workload cluster, under `upstream:` key | Routed to the unmodified upstream Karpenter subchart. Controls the actual application: images, controller settings, service accounts, etc. |
| **EXTRAS** | Workload cluster, at top level (not under `upstream:`) | Consumed by GS extras templates: `podLogs`, `global.podSecurityStandards` |

## Architecture

```
Management Cluster (Bundle)                 Workload Cluster (Karpenter)
┌─────────────────────────────────┐        ┌──────────────────────────────────┐
│  karpenter-bundle chart         │        │  karpenter chart                 │
│                                 │        │                                  │
│  ┌─────────────────────────┐    │   Flux │  ┌────────────────────────────┐  │
│  │ ConfigMap               │────│───────>│  │ upstream (karpenter v1.8.1)│  │
│  │ (workload values)       │    │        │  │ - Deployment               │  │
│  └─────────────────────────┘    │        │  │ - ServiceAccount (IRSA)    │  │
│                                 │        │  │ - RBAC                     │  │
│  ┌─────────────────────────┐    │        │  │ - Service, PDB, FlowSchema │  │
│  │ OCIRepository           │    │        │  │ - ServiceMonitor           │  │
│  │ HelmRelease             │    │        │  └────────────────────────────┘  │
│  └─────────────────────────┘    │        │                                  │
│                                 │        │  ┌────────────────────────────┐  │
│  ┌─────────────────────────┐    │        │  │ GS Extras                  │  │
│  │ IAM Roles (Crossplane)  │    │        │  │ - NetworkPolicy            │  │
│  │ - karpenter             │    │        │  │ - PSS PolicyException      │  │
│  │ - nodeclassgenerator    │    │        │  │ - PodLogs                  │  │
│  └─────────────────────────┘    │        │  └────────────────────────────┘  │
│                                 │        │                                  │
│  ┌─────────────────────────┐    │        │                                  │
│  │ SQS (Crossplane)        │    │        │                                  │
│  │ - Queue + Policy        │    │        │                                  │
│  │ - CloudWatch Event Rules│    │        │                                  │
│  └─────────────────────────┘    │        │                                  │
└─────────────────────────────────┘        └──────────────────────────────────┘
```

### Charts

| Chart | Cluster | Purpose |
|-------|---------|---------|
| `karpenter-bundle` | Management | Orchestrator: creates IAM roles (Crossplane), SQS queue + event rules, Flux resources (OCIRepository + HelmRelease), and ConfigMap with computed values |
| `karpenter` | Workload (via Flux) | Wraps the unmodified upstream Karpenter chart as a dependency (`alias: upstream`) and adds GS extras (NetworkPolicy, PSS exceptions, PodLogs) |

### Value flow

1. **Bundle values** are set on the management cluster (App CR or default `values.yaml`)
2. `giantswarm.setValues` helper computes:
   - IRSA role ARN from crossplane-config ConfigMap → `serviceAccount.annotations`
   - `settings.clusterName` from `clusterID`
   - `settings.interruptionQueue` as `{clusterID}-karpenter`
3. `giantswarm.combineImage` merges split `controller.image.registry` + `controller.image.repository` into a single `controller.image.repository` path
4. Proxy settings (`proxy.http`, `proxy.https`, `proxy.noProxy`) are converted to `controller.env` entries (HTTP_PROXY, HTTPS_PROXY, NO_PROXY)
5. `giantswarm.workloadValues` assembles the final structure:
   - Bundle-only keys (`clusterID`, `region`, `workersIamRole`, `ociRepositoryUrl`) are excluded
   - Upstream values are nested under `upstream:` key
   - Extras (`podLogs`, `global`) are placed at top level
6. Result is stored in a ConfigMap, consumed by the Flux HelmRelease via `valuesFrom`
7. Workload chart receives values, routing `upstream:` to the Karpenter subchart and top-level extras to GS templates

### Why this pattern

- **Unmodified upstream** — version bump is `helm dependency update`, no fork maintenance
- **Separation of concerns** — IAM, SQS, and Flux on management cluster; application on workload cluster
- **Single App CR** — install `karpenter-bundle` once on the management cluster

## Installation

Create an App CR on the management cluster:

```yaml
apiVersion: application.giantswarm.io/v1alpha1
kind: App
metadata:
  name: {cluster_id}-karpenter-bundle
  namespace: org-{org_name}
spec:
  catalog: giantswarm
  kubeConfig:
    inCluster: true
  name: karpenter-bundle
  namespace: org-{org_name}
  version: ""
```

## Testing

- `helm dependency update helm/karpenter/` — fetch upstream chart
- `helm template helm/karpenter/ -f helm/karpenter/ci/ci-values.yaml` — render workload chart
- `helm lint helm/karpenter/`
- `helm lint helm/karpenter-bundle/ -f helm/karpenter-bundle/ci/values.yaml`

## Credit

- [Karpenter](https://karpenter.sh/) — open-source node provisioning for Kubernetes
- [aws/karpenter-provider-aws](https://github.com/aws/karpenter-provider-aws)
