# Deployment & Helm Tooling Baseline (`deploy/`)

This document defines the deployment tooling baseline, Helm version requirements, installation procedures, namespace conventions, and directory organization for `open-iceberg-stack`.

## Helm Version Requirement

All chart installations across all epics require **Helm ≥ 3.12**.

- **Version Floor:** Helm 3.12 (or higher) is mandatory for stable OCI (Open Container Initiative) chart registry support, required for charts such as Bitnami OCI releases.
- **Incompatible Versions:** Helm 2 and Tiller are strictly forbidden due to security End-of-Life (EOL) and incompatibility with the stack workflow.
- **Policy:** Do not pin an exact patch version; any build meeting or exceeding `v3.12.0` is supported.

## Installation Instructions

### macOS (Homebrew)

```bash
brew install helm
```

### Linux

Using the official Helm installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Alternatively, use system package managers:
- **Debian / Ubuntu:**
  ```bash
  sudo apt-get install apt-transport-https --yes
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
  sudo apt-get update
  sudo apt-get install helm
  ```
- **Fedora / RHEL:** `sudo dnf install helm`
- **Snap:** `sudo snap install helm --classic`

### Windows

Using Chocolatey or Winget:

```powershell
# Chocolatey
choco install kubernetes-helm

# Winget
winget install Helm.Helm
```

## Verification

To verify that Helm is installed and meets the minimum version requirement, run:

```bash
helm version --short
```

Expected output should indicate version `v3.12.0` or higher (e.g., `v3.15.2` or `v4.0.5`).

## Namespace Convention & Strategy

`open-iceberg-stack` adopts a **Per-Component Namespace Strategy**.

### Strategy Rationale
- **Isolation & RBAC Scoping:** Scoping architecture layers into dedicated namespaces (`storage`, `catalog`, `ingestion`, `processing`, `query`, `bi`, `orchestration`, `maintenance`) enforces clean ServiceAccount, Secret, and RBAC boundaries between infrastructure layers.
- **Selective Teardown & Lifecycle:** Enables teardown or re-installation of individual components (e.g., resetting `query` or `ingestion`) without disrupting shared storage substrate (`storage`).
- **Resource Quota & Monitoring:** Simplifies resource consumption tracking and memory/CPU limit enforcement per architecture layer.

### Naming Compliance
All namespace names adhere strictly to **DNS-1123 sub-domain specifications**:
- Formatted in lowercase alphanumeric characters or `-`.
- Must start and end with an alphanumeric character.
- Maximum length of 63 characters.

### Defined Per-Component Namespaces
- `storage`: Object storage substrate (RustFS S3).
- `catalog`: Iceberg REST Catalog (Apache Iceberg REST service).
- `ingestion`: Streaming data ingestion substrate (Kafka / Strimzi).
- `processing`: Distributed compute engines (Flink / Spark).
- `query`: Distributed SQL query engine (Trino).
- `bi`: Analytics UI and visualization dashboards (Superset).
- `orchestration`: Workflow and pipeline orchestration (Airflow).
- `maintenance`: System housekeeping and utility jobs.

### Idempotent Creation & Usage
All namespaces are declared in [`deploy/namespaces.yaml`](namespaces.yaml) and created idempotently via `kubectl apply -f`:

```bash
# Provision or update all per-component namespaces idempotently:
kubectl apply -f deploy/namespaces.yaml

# Alternatively, run the helper script:
./scripts/setup-namespaces.sh

# Single namespace dry-run apply pattern:
kubectl create namespace storage --dry-run=client -o yaml | kubectl apply -f -
```

*Note:* Bare `kubectl create namespace <ns>` commands are strictly prohibited in scripts as they error if the target namespace already exists. Deploying workloads into the `default` namespace is forbidden.

## Repository Organization (`deploy/`)

Per-component Helm values and configuration manifests are organized under `deploy/`:
- `deploy/namespaces.yaml`: Consolidated per-component Namespace manifest.
- `deploy/cluster/`: Local Kubernetes cluster definition & provider config.
- `deploy/storage/`: Object storage substrate (RustFS) Helm values & manifests.
- `deploy/catalog/`: Iceberg REST Catalog values & configuration.
- `deploy/processing/`: Engine processing component values (Flink / Spark).
- `deploy/ingestion/`: Streaming ingestion components (Kafka).
- `deploy/query/`: Query engine components (Trino).
- `deploy/bi/`: Analytics and visualization components (Superset).
- `deploy/orchestration/`: Workflow orchestration components (Airflow).
- `deploy/maintenance/`: Maintenance & housekeeping utility manifests.
