terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Or the latest version you want to useee
    }
  }

  backend "s3" {
    bucket = "rrferro-terraform-state-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
