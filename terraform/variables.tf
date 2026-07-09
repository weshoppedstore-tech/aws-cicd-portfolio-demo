variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Used to name/tag resources"
  type        = string
  default     = "aws-cicd-portfolio-demo"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the site. Must be all lowercase, no underscores."
  type        = string
  # CHANGE THIS to something globally unique, e.g. "anthonydls-cicd-demo-2026"
  default     = "anthonydls-cicd-demo-389656351792"
}

variable "github_org_repo" {
  description = "Your GitHub org/user + repo, used to scope the OIDC trust policy"
  type        = string
  # e.g. "weshoppedstore-tech/aws-cicd-portfolio-demo"
 default     = "weshoppedstore-tech/aws-cicd-portfolio-demo"
}
