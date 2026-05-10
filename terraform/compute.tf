# ----------------------------------------------------------------------------
# EC2 instances + key pair + AMI lookup + k3s join token.
# ----------------------------------------------------------------------------

# Random secret shared between server and agents. Generated once at apply time
# (stored in tfstate) and injected into the user-data scripts.
resource "random_string" "k3s_token" {
  length  = 48
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Latest Ubuntu 22.04 LTS amd64 AMI from Canonical. We don't hardcode AMI IDs
# — they're region-specific and rotate over time.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu publisher)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Register our local public key with AWS as an EC2 key pair. Private key
# stays on the laptop — never sent to AWS.
resource "aws_key_pair" "k3s" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# ----------------------------------------------------------------------------
# k3s server (control plane). Runs the API server, scheduler, controller-mgr,
# and (since we don't taint it) also accepts pod workloads.
# ----------------------------------------------------------------------------
resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  key_name                    = aws_key_pair.k3s.key_name
  associate_public_ip_address = true

  # cloud-init script: installs k3s on first boot
  user_data = templatefile("${path.module}/user-data/server.sh.tftpl", {
    k3s_token = random_string.k3s_token.result
  })

  # If we change the user_data, replace the instance instead of trying to
  # update it in-place (you can't re-run user-data on a running EC2 anyway).
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-server"
    Role = "k3s-server"
  }
}

# ----------------------------------------------------------------------------
# k3s agent(s) — workers. Number controlled by var.agent_count.
# `count` makes this resource a list: aws_instance.agent[0], [1], etc.
# ----------------------------------------------------------------------------
resource "aws_instance" "agent" {
  count = var.agent_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  key_name                    = aws_key_pair.k3s.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data/agent.sh.tftpl", {
    k3s_token = random_string.k3s_token.result
    server_ip = aws_instance.server.private_ip
  })

  user_data_replace_on_change = true

  # Agent's user-data references the server's private IP, so Terraform infers
  # the dependency. Adding it explicitly here for clarity.
  depends_on = [aws_instance.server]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-agent-${count.index}"
    Role = "k3s-agent"
  }
}
