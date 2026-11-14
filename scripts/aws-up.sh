#!/usr/bin/env bash
# Create the AWS environment (EC2 + IAM) with Terraform and connect it to GitHub CD.
# Usage:  AWS_PROFILE=<profile> ./scripts/aws-up.sh        (Terraform asks before applying)
#         AWS_PROFILE=<profile> ./scripts/aws-up.sh -y     (no questions)
set -euo pipefail
cd "$(dirname "$0")/.."
TF_DIR=infra/terraform
AUTO=""; [ "${1:-}" = "-y" ] && AUTO="-auto-approve"

echo "==> 1. Checking prerequisites"
for tool in terraform aws gh curl; do
  command -v "$tool" >/dev/null || { echo "ERROR: $tool is not installed"; exit 1; }
done
gh auth status >/dev/null 2>&1 || { echo "ERROR: run 'gh auth login' first"; exit 1; }
ACCOUNT=$(aws sts get-caller-identity --query Account --output text) \
  || { echo "ERROR: AWS login failed (set AWS_PROFILE or run 'aws configure')"; exit 1; }
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)   # e.g. ilaycohen12/apples
echo "   AWS account: $ACCOUNT | GitHub repo: $REPO"

echo "==> 2. Does this account already have a GitHub OIDC provider?"
if aws iam list-open-id-connect-providers --output text | grep -q token.actions.githubusercontent.com; then
  CREATE_OIDC=false; echo "   yes -> reuse it"
else
  CREATE_OIDC=true;  echo "   no  -> Terraform will create it"
fi

echo "==> 3. Terraform init + apply"
terraform -chdir="$TF_DIR" init -input=false
PROFILE_VAR=(); [ -n "${AWS_PROFILE:-}" ] && PROFILE_VAR=(-var "aws_profile=$AWS_PROFILE")
terraform -chdir="$TF_DIR" apply $AUTO "${PROFILE_VAR[@]}" \
  -var "github_repo=$REPO" \
  -var "repo_url=https://github.com/$REPO.git" \
  -var "create_github_oidc=$CREATE_OIDC"

echo "==> 4. Reading Terraform outputs"
IP=$(terraform -chdir="$TF_DIR" output -raw public_ip)
INSTANCE=$(terraform -chdir="$TF_DIR" output -raw instance_id)
ROLE=$(terraform -chdir="$TF_DIR" output -raw cd_role_arn)

echo "==> 5. Connecting GitHub CD (repo variables)"
gh variable set EC2_PUBLIC_IP   --body "$IP"
gh variable set EC2_INSTANCE_ID --body "$INSTANCE"
gh variable set AWS_CD_ROLE_ARN --body "$ROLE"

echo "==> 6. Waiting for the site (server installs Docker + provisions, ~2-5 min)"
APPLES=""
for i in $(seq 1 60); do
  APPLES=$(curl -s -m 5 "http://$IP" | sed -n 's/.*<span id="apples">\([0-9]*\)<\/span>.*/\1/p' || true)
  [ -n "$APPLES" ] && break
  sleep 10
done
[ -n "$APPLES" ] || { echo "ERROR: site not ready after 10 min. Check /var/log/cloud-init-output.log on the server"; exit 1; }

echo
echo "✅ AWS environment is up: http://$IP  (shows $APPLES apples)"
echo "   CD is connected: every push to main now deploys here."
