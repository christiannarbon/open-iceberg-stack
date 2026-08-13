# Local Kubernetes Cluster Configuration (`deploy/cluster/`)

This directory contains the declarative cluster configuration for `open-iceberg-stack` using Minikube.

## Overview

The cluster runs under a dedicated, isolated Minikube profile (`open-iceberg`) using the `docker` driver and a pinned Kubernetes version (`v1.30.0`).

All cluster launch parameters are centrally declared in [`cluster.env`](cluster.env).

## Sizing Profiles

Two resource sizing profiles are defined:

| Profile | CPU (`--cpus`) | Memory (`--memory`) | Disk (`--disk-size`) | Selection Toggle |
| :--- | :--- | :--- | :--- | :--- |
| **Foundation (Default)** | 2 vCPU | 4096 MiB (4 GiB) | 20 GiB | Default (`FULL_STACK=0`) |
| **Lean Full-Stack (Opt-in)** | 4 vCPU | 7168 MiB (7 GiB) | 30 GiB | `FULL_STACK=1` |

### 1. Foundation Profile (Default)
- **Parameters:** `--cpus 2 --memory 4096 --disk-size 20g`
- **Use Case:** Provisions the local Kubernetes cluster and RustFS S3 storage substrate. Lightweight design ensures compatibility with typical development laptops.

### 2. Lean Full-Stack Profile (Opt-in)
- **Parameters:** `--cpus 4 --memory 7168 --disk-size 30g`
- **Use Case:** Required when deploying the full streaming and query stack (Kafka, Flink, Trino, Superset).
- **Activation:** Set `FULL_STACK=1` prior to invoking cluster creation (e.g., `FULL_STACK=1 ./scripts/cluster-up.sh` or `FULL_STACK=1 minikube start ...`).

## Resource Constraints & OOM / Swap Caveats

- **Disk Sizing Ceiling:** The 30 GiB disk size ceiling is not pre-allocated, but represents a strict upper bound. 30 GiB is a tight budget intended to hold container images alongside lean Persistent Volume Claims (e.g., RustFS 10 GiB PVC, Kafka 8 GiB PVC).
- **Resource Budget Policy:** The full stack can only run within 7 GiB RAM if every downstream component enforces strict resource capping (single replicas, trimmed JVM heap allocations).
- **OOM / Swap Risk:** Expect potential Out-Of-Memory (OOM) or swap pressure when concurrent data ingestion (Kafka/Flink) and analytical queries (Trino/Superset) overlap.

## Profile Isolation & Security

- All cluster operations target the dedicated profile `open-iceberg` (`-p open-iceberg`).
- Operations will **never** target or modify the default Minikube profile or host `docker-desktop` context, ensuring clean teardown without risk to unrelated local clusters.

## Invocation Example

```bash
# Load cluster variables for Default (Foundation) profile:
source deploy/cluster/cluster.env
minikube start ${MINIKUBE_START_ARGS}

# Load cluster variables for Full-Stack profile:
FULL_STACK=1 source deploy/cluster/cluster.env
minikube start ${MINIKUBE_START_ARGS}
```
