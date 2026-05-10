# Where Terraform stores its state and the lock used to prevent concurrent
# applies. Backend blocks are evaluated before variables are read, so the
# profile name is hardcoded here. If you fork this on a different machine,
# change `profile` to whatever you have in ~/.aws/credentials.
terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "gitops-pipeline-k3s-tfstate-972293797395"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    profile      = "gitops"
    encrypt      = true
    use_lockfile = true # S3 native locking (TF 1.10+); replaces deprecated dynamodb_table
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
