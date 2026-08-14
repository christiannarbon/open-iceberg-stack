#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/deploy/cluster/cluster.env"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck source=../deploy/cluster/cluster.env
  source "${ENV_FILE}"
fi

PROFILE="${PROFILE:-open-iceberg}"

echo "======================================================================="
echo "Teardown Minikube Cluster: ${PROFILE}"
echo "======================================================================="

# Delete minikube profile if it exists
if minikube status -p "${PROFILE}" >/dev/null 2>&1 || minikube profile list 2>/dev/null | grep -q "${PROFILE}"; then
  echo "Deleting Minikube profile '${PROFILE}'..."
  minikube delete -p "${PROFILE}"
else
  echo "Minikube profile '${PROFILE}' is not present."
fi

# Clean up only this specific cluster's kubeconfig context and cluster definitions
echo "Cleaning up kubeconfig context for '${PROFILE}'..."
kubectl config delete-context "${PROFILE}" >/dev/null 2>&1 || true
kubectl config delete-cluster "${PROFILE}" >/dev/null 2>&1 || true
kubectl config unset "users.${PROFILE}" >/dev/null 2>&1 || true
kubectl config unset "contexts.${PROFILE}" >/dev/null 2>&1 || true

echo "======================================================================="
echo "Teardown of cluster '${PROFILE}' complete."
echo "======================================================================="
