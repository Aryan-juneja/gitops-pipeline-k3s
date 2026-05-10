# Inputs to this Terraform configuration. Values come from terraform.tfvars
# (or environment vars, or CLI flags). Defaults are used when nothing is set.

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name (~/.aws/credentials) to use"
  type        = string
  default     = "gitops"
}

variable "project_name" {
  description = "Used as a prefix and tag on every resource"
  type        = string
  default     = "gitops-pipeline-k3s"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form (X.X.X.X/32). Allowed to SSH and reach the k8s API."
  type        = string

  validation {
    condition     = can(regex("^[0-9.]+/32$", var.my_ip_cidr))
    error_message = "Must be a single IP in CIDR form, e.g. 203.0.113.5/32."
  }
}

variable "instance_type" {
  description = "EC2 instance type for both server and agent. t3.micro is free-tier eligible."
  type        = string
  default     = "t3.micro"
}

variable "agent_count" {
  description = "Number of k3s agent (worker) nodes. 0 = single-node cluster. 1 = multi-node."
  type        = number
  default     = 1
}

variable "ssh_public_key_path" {
  description = "Path to the local SSH public key file used for EC2 access."
  type        = string
  default     = "~/.ssh/k3s-gitops.pub"
}
