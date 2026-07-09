terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ─────────────────────────────────────────────────────────────
  # State is kept local for this demo (simplest for a one-day build).
  # If you want remote state later, create an S3 bucket + DynamoDB
  # lock table first, then uncomment and fill in below.
  # ─────────────────────────────────────────────────────────────
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "aws-cicd-portfolio-demo/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# CloudFront requires ACM certs in us-east-1 specifically.
# We don't use a custom domain in this demo, so this is unused for now,
# but kept here in case you add anthonydls.com later.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
