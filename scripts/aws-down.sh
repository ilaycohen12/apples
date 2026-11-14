#!/usr/bin/env bash
# Delete the AWS environment (EC2, firewall, IAM roles, Elastic IP) and disconnect GitHub CD.
# Local Docker setup is NOT touched.
# Usage:  AWS_PROFILE=<profile> ./scripts/aws-down.sh        (Terraform asks before destroying)
#         AWS_PROFILE=<profile> ./scripts/aws-down.sh -y     (no questions)
set -euo pipefail
cd "$(dirname "$0")/.."
TF_DIR=infra/terraform
AUTO=""; [ "${1:-}" = "-y" ] && AUTO="-auto-approve"

echo "==> 1. Checking prerequisites"
for tool in terraform aws gh; do
  command -v "$tool" >/dev/null || { echo "ERROR: $tool is not installed"; exit 1; }
done
aws sts get-caller-identity >/dev/null || { echo "ERROR: AWS login failed"; exit 1; }
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)

echo "==> 2. Terraform destroy"
PROFILE_VAR=(); [ -n "${AWS_PROFILE:-}" ] && PROFILE_VAR=(-var "aws_profile=$AWS_PROFILE")
terraform -chdir="$TF_DIR" init -input=false >/dev/null
terraform -chdir="$TF_DIR" destroy $AUTO "${PROFILE_VAR[@]}" -var "github_repo=$REPO"

echo "==> 3. Disconnecting GitHub CD (removing repo variables -> CD will skip)"
for v in EC2_PUBLIC_IP EC2_INSTANCE_ID AWS_CD_ROLE_ARN; do
  gh variable delete "$v" 2>/dev/null || true   # ignore if already gone
done

echo
echo "✅ AWS environment deleted. Local setup still works: ./scripts/provision.sh"
