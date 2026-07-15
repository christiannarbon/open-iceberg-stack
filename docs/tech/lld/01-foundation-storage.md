# LLD 01 — Foundation & Storage Substrate

**Layer:** Kubernetes + S3 storage

## Purpose & scope

Provision the local Kubernetes cluster and the S3-compatible object store that
every later layer builds on. **In scope:** cluster, default StorageClass, Helm
tooling baseline, MinIO with persistent storage, medallion buckets. **Out of
scope:** TLS, production hardening, any catalog or engine.

## Component internals

```mermaid
flowchart TB
    subgraph minikube["Minikube cluster"]
        sc[Default StorageClass<br/>dynamic PV provisioner]
        subgraph minioRel["Helm release: minio (ns: storage)"]
            deploy[MinIO Deployment/StatefulSet]
            svcApi[[Service :9000 — S3 API]]
            svcCon[[Service :9001 — Console]]
            pvc[(PVC 10Gi)]
            secret[Secret: root user/password]
            deploy --- svcApi
            deploy --- svcCon
            deploy --- pvc
            secret --> deploy
        end
        sc -.provisions.-> pvc
    end
    buckets["Buckets:<br/>lakehouse-raw · lakehouse-silver<br/>lakehouse-gold · lakehouse-platinum"]
    deploy --> buckets
```

## Configuration contract

| Concern | Setting | Notes |
| :--- | :--- | :--- |
| Cluster | Minikube (default provider), `deploy/cluster/` | default StorageClass must exist for dynamic PVCs |
| Helm tooling | pinned chart versions, repo-add script | declarative install, no ad-hoc `--set` of structural config |
| MinIO deploy | MinIO Helm chart, `deploy/storage/` | pinned version |
| MinIO persistence | `persistence.enabled=true`, `storageClass`, `size=10Gi` | lean local profile |
| MinIO ports | S3 API `9000`, console `9001` | port-forward for host access |
| Credentials | root user/password via **Secret**/env | no plaintext in `values.yaml` (placeholder only) |
| Buckets | `lakehouse-raw/silver/gold/platinum` | created idempotently (job/script) |
| Addressing | **path-style** access required | MinIO ≠ virtual-hosted-style |

### Bucket layout (medallion)

```mermaid
flowchart LR
    raw[(lakehouse-raw<br/>Flink writes)]
    silver[(lakehouse-silver<br/>dbt staging)]
    gold[(lakehouse-gold<br/>dbt marts)]
    plat[(lakehouse-platinum<br/>reserved)]
    raw --> silver --> gold --> plat
```

## Durability model

MinIO's object data lives on a PVC provisioned by the default StorageClass, not
in the pod. The pod is therefore disposable: if it is deleted or rescheduled, the
PVC re-binds to the replacement and all objects remain intact. This is what lets
every layer above treat MinIO as durable storage.

## Inputs consumed / outputs produced

**Consumes:** nothing — this is the foundation layer.

**Produces — the foundation contract (to all layers above):**

- Running cluster + **default StorageClass** (dynamic PVCs).
- **Helm/deployment tooling baseline** (pinned repos, install targets).
- MinIO **internal endpoint** `minio.<ns>.svc.cluster.local:9000` + path-style
  requirement; external port-forward URL + console.
- The four **medallion buckets**.
- Root credential handling pattern (Secret/env, gitignored).

Target folders: `deploy/cluster/` (cluster provisioning + StorageClass baseline),
`deploy/storage/` (MinIO Helm values), `scripts/` (bucket creation).
