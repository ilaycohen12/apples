# Printed at the end of "terraform apply" (and anytime with "terraform output").

output "public_ip" {
  description = "Public IP of the apples server"
  value       = aws_instance.apples.public_ip
}

output "url" {
  description = "Open this in the browser (ready ~3-5 min after apply)"
  value       = "http://${aws_instance.apples.public_ip}"
}

output "instance_id" {
  description = "EC2 instance ID (for the AWS console / CLI)"
  value       = aws_instance.apples.id
}

output "cd_role_arn" {
  description = "Role that GitHub Actions assumes (put in repo variable AWS_CD_ROLE_ARN)"
  value       = aws_iam_role.github_cd.arn
}
