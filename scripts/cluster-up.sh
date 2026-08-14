#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/deploy/cluster/cluster.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Error: Cluster environment file not found at ${ENV_FILE}" >&2
  exit 1
fi

# Source cluster configuration
# shellcheck source=../deploy/cluster/cluster.env
source "${ENV_FILE}"

PROFILE="${PROFILE:-open-iceberg}"
ADDONS="${ADDONS:-default-storageclass storage-provisioner}"

echo "======================================================================="
echo "Provisioning Minikube Cluster: ${PROFILE}"
echo "Sizing Profile: FULL_STACK=${FULL_STACK:-0} (CPUs=${CPUS}, Memory=${MEMORY}MB, Disk=${DISK_SIZE})"
echo "======================================================================="

# Check if cluster is already running
if minikube status -p "${PROFILE}" >/dev/null 2>&1; then
  echo "Cluster '${PROFILE}' is already running."
else
  echo "Starting cluster '${PROFILE}' with parameters: ${MINIKUBE_START_ARGS}"
  # Note: MINIKUBE_START_ARGS is intentionally unquoted to expand arguments
  # shellcheck disable=SC2086
  minikube start ${MINIKUBE_START_ARGS}
fi

# Enable required StorageClass addons
for addon in ${ADDONS}; do
  echo "Enabling addon '${addon}' on profile '${PROFILE}'..."
  minikube addons enable "${addon}" -p "${PROFILE}"
done

# Ensure active kubectl context is open-iceberg
kubectl config use-context "${PROFILE}" >/dev/null 2>&1 || true

echo "======================================================================="
echo "Cluster '${PROFILE}' is ready."
echo "Active context: $(kubectl config current-context 2>/dev/null || echo '${PROFILE}')"
echo "======================================================================="
