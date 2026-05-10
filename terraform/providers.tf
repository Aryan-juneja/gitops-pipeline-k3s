# Tells Terraform how to talk to AWS — which region, which credential profile,
# and any tags we want auto-applied to every resource we create.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
