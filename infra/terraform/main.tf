# The AWS resources: find Ubuntu image, firewall, and the EC2 server.

# ---------- Find the latest official Ubuntu 24.04 image ----------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (official Ubuntu publisher)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# ---------- Use the account's default network (VPC) ----------
data "aws_vpc" "default" {
  default = true
}

# ---------- Firewall (Security Group) ----------
resource "aws_security_group" "apples" {
  name        = "apples-web"
  description = "Allow HTTP in, all traffic out"
  vpc_id      = data.aws_vpc.default.id

  # IN: only port 80 (nginx). No SSH, no DB port.
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_http_cidr]
  }

  # OUT: everything (needed to install Docker, clone GitHub, pull images)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- The server ----------
resource "aws_instance" "apples" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.apples.id]
  iam_instance_profile   = aws_iam_instance_profile.server.name # lets SSM agent receive commands

  # Startup script, with repo URL + branch filled in
  user_data = templatefile("${path.module}/user-data.sh", {
    repo_url    = var.repo_url
    repo_branch = var.repo_branch
  })
  user_data_replace_on_change = true # changed script => new server

  # Disk: 20GB (default 8GB is too small for Docker images). Free tier = 30GB.
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # Security: require IMDSv2 (protects instance metadata from SSRF attacks)
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "apples-server"
  }
}
