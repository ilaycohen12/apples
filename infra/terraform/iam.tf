# Permissions for CD: the server accepts SSM commands, and GitHub Actions
# can log in to AWS (OIDC, no stored keys) and send those commands.

data "aws_caller_identity" "current" {} # this AWS account's ID

# ================= 1. Server role (EC2 -> SSM) =================
# Lets the SSM agent on the server register with AWS and receive commands.
resource "aws_iam_role" "server" {
  name = "apples-server"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" } # only EC2 can use this role
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "server_ssm" {
  role       = aws_iam_role.server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # AWS-managed SSM policy
}

# An "instance profile" is the wrapper that attaches a role to an EC2 server
resource "aws_iam_instance_profile" "server" {
  name = "apples-server"
  role = aws_iam_role.server.name
}

# ================= 2. GitHub OIDC (GitHub -> AWS, no keys) =================
# Tell AWS to trust GitHub's identity tokens.
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_github_oidc ? 1 : 0 # create only if asked
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# The provider's ARN is always the same format, whether we created it or it already existed
locals {
  github_oidc_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Role that ONLY GitHub Actions of this repo, on main branch, can assume.
resource "aws_iam_role" "github_cd" {
  name       = "apples-github-cd"
  depends_on = [aws_iam_openid_connect_provider.github] # provider must exist first (if we create it)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main" }
      }
    }]
  })
}

# What GitHub can do: send a shell command to THIS server only, and read the result.
resource "aws_iam_role_policy" "github_cd" {
  name = "send-deploy-command"
  role = aws_iam_role.github_cd.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "ssm:SendCommand"
        Resource = [
          aws_instance.apples.arn,                                 # only our server
          "arn:aws:ssm:${var.region}::document/AWS-RunShellScript" # only "run shell script"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations"] # read the result
        Resource = "*"
      }
    ]
  })
}
