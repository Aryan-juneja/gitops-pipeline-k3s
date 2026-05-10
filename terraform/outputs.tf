# Outputs print after `terraform apply` and can be queried with
# `terraform output <name>`. Useful for grabbing values into shell scripts.

output "vpc_id" {
  description = "ID of the VPC we created"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "server_public_ip" {
  description = "Public IP of the k3s server (control plane)"
  value       = aws_instance.server.public_ip
}

output "agent_public_ips" {
  description = "Public IPs of the k3s agent nodes"
  value       = aws_instance.agent[*].public_ip
}

output "ssh_to_server" {
  description = "Copy-paste SSH command for the server"
  value       = "ssh -i ~/.ssh/k3s-gitops ubuntu@${aws_instance.server.public_ip}"
}

