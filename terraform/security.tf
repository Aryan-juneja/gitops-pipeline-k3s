# ----------------------------------------------------------------------------
# Security group for k3s nodes — both server and agent share one SG.
# In strict production, you'd split these (least privilege). For a 2-node
# cluster this keeps things readable.
# ----------------------------------------------------------------------------
resource "aws_security_group" "k3s" {
  name        = "${var.project_name}-k3s"
  description = "k3s server + agent traffic"
  vpc_id      = aws_vpc.main.id

  # SSH from your laptop only.
  ingress {
    description = "SSH from operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Kubernetes API server. Only your laptop talks to it directly via kubectl.
  ingress {
    description = "k8s API from operator IP"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # HTTP / HTTPS from the world — apps exposed through the ingress controller.
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal traffic between any instance in this SG. Covers all k3s
  # control-plane <-> agent ports without enumerating each (kubelet 10250,
  # flannel 8472/UDP, etc.). `self = true` means "from anything sharing this SG".
  ingress {
    description = "All internal traffic between k3s nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # All outbound — instances need to reach github.com, get.k3s.io,
  # ECR/quay/ghcr for container images, etc.
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-k3s"
  }
}
