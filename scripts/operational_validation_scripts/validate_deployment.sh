#!/bin/bash

cd ~/EC2-Behind-a-Load-Balancer/terraform 

set -euo pipefail

alb_url="$(terraform output -raw alb_url)"
target_group_arn="$(terraform output -raw target_group_arn)"

echo "ALB URL: $alb_url"
echo "Target Group ARN: $target_group_arn"
echo

echo "Checking ALB homepage..."
if curl --fail --silent "$alb_url" | grep -q "EC2 instance running"; then
  echo "[PASS] ALB homepage reachable"
else
  echo "[FAIL] ALB homepage check failed"
  exit 1
fi

echo "Checking ALB health endpoint..."
if curl --fail --silent "$alb_url/health" | grep -q "OK"; then
  echo "[PASS] ALB health endpoint returned OK"
else
  echo "[FAIL] ALB health endpoint check failed"
  exit 1
fi

echo "Checking target group health..."
target_state="$(aws elbv2 describe-target-health \
  --target-group-arn "$target_group_arn" \
  --query "TargetHealthDescriptions[0].TargetHealth.State" \
  --output text)"

if [ "$target_state" = "healthy" ]; then
  echo "[PASS] Target group reports healthy"
else
  echo "[FAIL] Target group state is: $target_state"
  exit 1
fi

echo
echo "Deployment validation complete."