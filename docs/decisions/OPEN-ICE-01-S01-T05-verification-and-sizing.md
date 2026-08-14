# OPEN-ICE-01-S01-T05 — Cluster Lifecycle Verification & Resource Sizing Record

- **Status:** APPROVED
- **Date:** 2026-08-15
- **Epic:** OPEN-ICE-01 (Foundation & Storage Substrate)
- **Story:** OPEN-ICE-01-S01 (Provision a local Kubernetes cluster)

## Overview

This document records the empirical lifecycle verification of the local Minikube Kubernetes cluster (`open-iceberg`) and defines the dual resource sizing profiles for `open-iceberg-stack`.

## Lifecycle Performance Results

The complete create -> ready -> teardown loop was benchmarked using the automated repository helper scripts:

| Lifecycle Action | Execution Command | Time Elapsed | Target Budget | Verification Result |
| :--- | :--- | :--- | :--- | :--- |
| **Cluster Bring-Up** | `./scripts/cluster-up.sh` | **19.05 sec** | < 180 sec (3 min) | PASS (`kubectl get nodes` -> Ready) |
| **StorageClass Check** | `kubectl get storageclass` | **Instant** | Immediate | PASS (`standard (default)` active) |
| **Cluster Teardown** | `./scripts/cluster-down.sh` | **18.71 sec** | < 60 sec | PASS (Profile & context cleanly removed) |

### Empirical Command Outputs

```text
$ ./scripts/cluster-up.sh
=======================================================================
Provisioning Minikube Cluster: open-iceberg
Sizing Profile: FULL_STACK=0 (CPUs=2, Memory=4096MB, Disk=20g)
=======================================================================
Starting cluster 'open-iceberg' with parameters: -p open-iceberg --driver=docker --kubernetes-version=v1.30.0 --cpus=2 --memory=4096 --disk-size=20g
* [open-iceberg] minikube v1.38.1 on Darwin 26.5.2 (arm64)
* Done! kubectl is now configured to use "open-iceberg" cluster and "default" namespace by default
=======================================================================
Cluster 'open-iceberg' is ready.
Active context: open-iceberg
=======================================================================

$ kubectl get nodes
NAME           STATUS   ROLES           AGE   VERSION
open-iceberg   Ready    control-plane   7s    v1.30.0

$ kubectl get storageclass
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  4s
```

## Resource Sizing Specifications

Two sizing profiles are established for local development:

### 1. Foundation Profile (Default)
- **Allocation:** `--cpus 2 --memory 4096 --disk-size 20g` (2 vCPU / 4 GiB RAM / 20 GiB disk ceiling)
- **Target Workload:** Provisions the local Kubernetes cluster infrastructure and RustFS S3 object storage substrate.
- **Minimum System Requirement:** Dual-core CPU, 8 GiB host RAM. Intentionally lightweight to enable quick local onboarding.

### 2. Lean Full-Stack Profile (Opt-in)
- **Allocation:** `--cpus 4 --memory 7168 --disk-size 30g` (4 vCPU / 7 GiB RAM / 30 GiB disk ceiling)
- **Activation:** `FULL_STACK=1 ./scripts/cluster-up.sh`
- **Target Workload:** Required when deploying the complete analytical data platform (Kafka streaming, Flink processing, Trino query engine, Superset visualization).
- **Resource Budget Policy:** The 30 GiB disk ceiling holds container images alongside lean PVCs (RustFS 10Gi, Kafka 8Gi). Requires strict component resource caps (single replicas, small JVM heap limits).
- **Workload Caveats:** Potential OOM or swap pressure when concurrent data ingestion and heavy analytical queries overlap.

## Quickstart Prerequisites Summary

Contributors running `open-iceberg-stack` must ensure:
1. Docker Desktop / Container Runtime active with `docker` driver support.
2. Minikube ≥ 1.32 and `kubectl` ≥ 1.27 installed.
3. Minimum 8 GiB host RAM for Foundation profile (16+ GiB recommended for Full-Stack profile).
