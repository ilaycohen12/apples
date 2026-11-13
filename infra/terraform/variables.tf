# Settings for the deployment. Override with -var or a terraform.tfvars file.

variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use (null = use env credentials, e.g. in CI)"
  type        = string
  default     = "personal"
}

variable "instance_type" {
  description = "EC2 size. t3.micro = 2 vCPU, 1GB RAM, free-tier eligible"
  type        = string
  default     = "t3.micro"
}

variable "repo_url" {
  description = "Git repo the server clones and provisions"
  type        = string
  default     = "https://github.com/ilaycohen12/apples.git"
}

variable "repo_branch" {
  description = "Branch to deploy"
  type        = string
  default     = "main"
}

variable "allowed_http_cidr" {
  description = "Who can open the website (0.0.0.0/0 = everyone)"
  type        = string
  default     = "0.0.0.0/0"
}
