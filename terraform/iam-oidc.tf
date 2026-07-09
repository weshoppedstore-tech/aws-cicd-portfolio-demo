# ─────────────────────────────────────────────────────────────
# GitHub OIDC — this is the piece that lets GitHub Actions deploy
# to AWS with NO stored access keys / secrets. GitHub proves its
# identity to AWS with a short-lived signed token on every run.
# ─────────────────────────────────────────────────────────────

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Trust policy: only workflows running from YOUR repo, on the main
# branch, are allowed to assume this role. Nobody else's GitHub repo
# can use it — this scoping is what makes OIDC safe.
data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${var.project_name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# Permissions policy: scoped ONLY to what the pipeline needs —
# read/write this one S3 bucket, invalidate this one CloudFront
# distribution, plus read-only access so `terraform plan` works.
data "aws_iam_policy_document" "github_deploy_permissions" {
  statement {
    sid    = "S3SiteBucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }

  statement {
    sid    = "CloudFrontInvalidation"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:GetDistribution",
    ]
    resources = [aws_cloudfront_distribution.site.arn]
  }

  statement {
    sid    = "TerraformReadForPlanApply"
    effect = "Allow"
    actions = [
      "s3:GetBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketOwnershipControls",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:ListDistributions",
      "iam:GetOpenIDConnectProvider",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name   = "${var.project_name}-deploy-permissions"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy_permissions.json
}

output "github_actions_role_arn" {
  description = "Paste this into your GitHub Actions workflow / repo variable"
  value       = aws_iam_role.github_deploy.arn
}
