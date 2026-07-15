# Low-Level Design — Open Iceberg Stack

Component-internal design for each layer of the stack: the workloads, their
configuration contracts, the sequence flows that make them work, and the wiring
each layer hands to the next. For the high-level (whole-system) view, see
[`../architecture/`](../architecture/).

Each LLD describes the system as built and is written to stand on its own.

## Index

| # | LLD | Core component(s) |
| :- | :--- | :--- |
| 01 | [Foundation & Storage](01-foundation-storage.md) | Minikube, MinIO, PVCs, buckets |
| 02 | [Ingestion Backbone](02-ingestion-backbone.md) | Kafka (KRaft), Python producer |
| 03 | [Governance & Catalog](03-governance-catalog.md) | Apache Polaris, realm, RBAC, vending |
| 04 | [Stream Processing](04-stream-processing.md) | Flink Operator, custom image, Iceberg sink |
| 05 | [Compute Engine](05-compute-engine.md) | Trino coordinator/workers, iceberg connector |
| 06 | [Orchestration & Transform](06-orchestration-transform.md) | Dagster, dbt-trino, sensor |
| 07 | [Day-Two Operations](07-day-two-operations.md) | Maintenance SQL, scheduled Dagster jobs |
| 08 | [BI & Visualization](08-bi-visualization.md) | Superset, Redis, PostgreSQL |

The layers are ordered by dependency: each builds on those above it.

## How to read an LLD

Every document follows the same shape:

1. **Purpose & scope** — what this component does and its boundaries.
2. **Component internals** — a diagram of the pieces inside the workload.
3. **Configuration contract** — the concrete config / properties that make it
   work (ports, connector props, values keys).
4. **Key sequence(s)** — the runtime flow(s) the component exists to perform.
5. **Inputs consumed / outputs produced** — the contract with adjacent layers.

## Conventions used throughout

- In-cluster DNS: `<svc>.<namespace>.svc.cluster.local:<port>` (see
  [architecture/03](../architecture/03-deployment-topology.md)).
- MinIO is always addressed **path-style** (`s3.path-style-access=true`).
- Iceberg table identifiers are `<catalog>.<namespace>.<table>`.
- Secrets are injected via K8s Secrets/env; repo holds placeholders only.
