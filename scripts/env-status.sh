#!/usr/bin/env bash
set -euo pipefail

#
# env-status.sh — Check the current state of your AWS environment
#
# Shows whether EKS nodes and RDS are running, stopped, or missing.
# Useful before starting/stopping to know current state.
#
# Usage:
#   ./scripts/env-status.sh dev
#   ./scripts/env-status.sh prod
#

REGION="${AWS_DEFAULT_REGION:-us-east-1}"

usage() {
  echo "Usage: $0 <environment>"
  echo "  environment: dev | prod"
  echo ""
  echo "Examples:"
  echo "  $0 dev      # Check dev environment status"
  echo "  $0 prod     # Check prod environment status"
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

ENV="$1"
if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "Error: environment must be 'dev' or 'prod'"
  usage
fi

CLUSTER_NAME="petclinic-${ENV}"
NODEGROUP_NAME="petclinic-${ENV}-nodes"
RDS_INSTANCE_ID="petclinic-${ENV}-mysql"

echo "============================================"
echo "  Environment Status: ${ENV}"
echo "  Region: ${REGION}"
echo "============================================"
echo ""

# --- EKS Cluster ---
echo "--- EKS Cluster: ${CLUSTER_NAME} ---"

CLUSTER_STATUS=$(aws eks describe-cluster \
  --name "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --query 'cluster.status' \
  --output text 2>/dev/null || echo "NOT FOUND")

echo "  Cluster status: ${CLUSTER_STATUS}"

if [[ "${CLUSTER_STATUS}" != "NOT FOUND" ]]; then
  CLUSTER_VERSION=$(aws eks describe-cluster \
    --name "${CLUSTER_NAME}" \
    --region "${REGION}" \
    --query 'cluster.version' \
    --output text)
  echo "  Kubernetes version: ${CLUSTER_VERSION}"
fi

echo ""

# --- EKS Node Group ---
echo "--- Node Group: ${NODEGROUP_NAME} ---"

NODEGROUP_STATUS=$(aws eks describe-nodegroup \
  --cluster-name "${CLUSTER_NAME}" \
  --nodegroup-name "${NODEGROUP_NAME}" \
  --region "${REGION}" \
  --query 'nodegroup.status' \
  --output text 2>/dev/null || echo "NOT FOUND")

if [[ "${NODEGROUP_STATUS}" == "NOT FOUND" ]]; then
  echo "  Status: NOT FOUND"
else
  echo "  Status: ${NODEGROUP_STATUS}"

  SCALING_INFO=$(aws eks describe-nodegroup \
    --cluster-name "${CLUSTER_NAME}" \
    --nodegroup-name "${NODEGROUP_NAME}" \
    --region "${REGION}" \
    --query 'nodegroup.scalingConfig.{min:minSize,max:maxSize,desired:desiredSize}' \
    --output text)

  DESIRED=$(echo "${SCALING_INFO}" | awk '{print $1}')
  MAX=$(echo "${SCALING_INFO}" | awk '{print $2}')
  MIN=$(echo "${SCALING_INFO}" | awk '{print $3}')

  echo "  Nodes: desired=${DESIRED}, min=${MIN}, max=${MAX}"

  INSTANCE_TYPE=$(aws eks describe-nodegroup \
    --cluster-name "${CLUSTER_NAME}" \
    --nodegroup-name "${NODEGROUP_NAME}" \
    --region "${REGION}" \
    --query 'nodegroup.instanceTypes[0]' \
    --output text)
  echo "  Instance type: ${INSTANCE_TYPE}"

  if [[ "${DESIRED}" == "0" ]]; then
    echo "  ** PAUSED (scaled to 0) — no compute costs **"
  fi
fi

echo ""

# --- RDS Instance ---
echo "--- RDS Instance: ${RDS_INSTANCE_ID} ---"

RDS_STATUS=$(aws rds describe-db-instances \
  --db-instance-identifier "${RDS_INSTANCE_ID}" \
  --region "${REGION}" \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text 2>/dev/null || echo "NOT FOUND")

if [[ "${RDS_STATUS}" == "NOT FOUND" ]]; then
  echo "  Status: NOT FOUND"
else
  echo "  Status: ${RDS_STATUS}"

  RDS_CLASS=$(aws rds describe-db-instances \
    --db-instance-identifier "${RDS_INSTANCE_ID}" \
    --region "${REGION}" \
    --query 'DBInstances[0].DBInstanceClass' \
    --output text)
  echo "  Instance class: ${RDS_CLASS}"

  RDS_ENGINE=$(aws rds describe-db-instances \
    --db-instance-identifier "${RDS_INSTANCE_ID}" \
    --region "${REGION}" \
    --query 'DBInstances[0].EngineVersion' \
    --output text)
  echo "  MySQL version: ${RDS_ENGINE}"

  if [[ "${RDS_STATUS}" == "stopped" ]]; then
    echo "  ** STOPPED — no compute costs **"
    echo "  Note: AWS auto-restarts stopped RDS after 7 days."
  fi
fi

echo ""

# --- Cost Estimate ---
echo "--- Estimated Daily Cost ---"

RUNNING_COST=0
PAUSED_ITEMS=""

# EKS control plane always costs
echo "  EKS control plane:  ~\$3.30/day (always on)"
RUNNING_COST=3.30

if [[ "${NODEGROUP_STATUS}" != "NOT FOUND" && "${DESIRED}" != "0" ]]; then
  echo "  EC2 nodes (${DESIRED}x ${INSTANCE_TYPE}): ~\$2-5/day"
  RUNNING_COST=$(echo "$RUNNING_COST + 3.5" | bc 2>/dev/null || echo "$RUNNING_COST")
else
  PAUSED_ITEMS="${PAUSED_ITEMS}  EC2 nodes: \$0 (scaled to 0)\n"
fi

if [[ "${RDS_STATUS}" == "available" ]]; then
  echo "  RDS (${RDS_CLASS}):  ~\$1-2/day"
  RUNNING_COST=$(echo "$RUNNING_COST + 1.5" | bc 2>/dev/null || echo "$RUNNING_COST")
elif [[ "${RDS_STATUS}" == "stopped" ]]; then
  PAUSED_ITEMS="${PAUSED_ITEMS}  RDS: \$0 (stopped)\n"
fi

if [[ -n "${PAUSED_ITEMS}" ]]; then
  echo ""
  echo "  Paused (no charge):"
  echo -e "${PAUSED_ITEMS}"
fi

echo ""
echo "============================================"
if [[ "${DESIRED:-0}" == "0" && "${RDS_STATUS}" == "stopped" ]]; then
  echo "  Environment is PAUSED. Only EKS control plane costs apply."
  echo "  Run: ./scripts/start-env.sh ${ENV}"
elif [[ "${DESIRED:-0}" == "0" || "${RDS_STATUS}" == "stopped" ]]; then
  echo "  Environment is PARTIALLY running."
else
  echo "  Environment is FULLY running."
  echo "  Run: ./scripts/stop-env.sh ${ENV}  (when done for the day)"
fi
echo "============================================"
