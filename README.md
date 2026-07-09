# AWS CI/CD Portfolio Demo — Anthony Delos Santos

A live, end-to-end demo of infrastructure automation: **GitHub Actions + Terraform**
deploy a static site to **S3 + CloudFront**, authenticated with **OIDC** (no stored
AWS credentials, ever).

The "site" being deployed is intentionally simple — a single self-contained
`index.html`. The point of this repo isn't the website; it's the pipeline that
builds and ships it automatically, the same way every time.

## What this proves
- Infrastructure is defined as code (Terraform) — not clicked together in the
  AWS console.
- Deployments happen through a pipeline (GitHub Actions) — not manual uploads.
- Authentication uses short-lived OIDC tokens — not long-lived access keys
  sitting in a secrets file.

## Architecture
```
GitHub push (main branch)
        │
        ▼
GitHub Actions workflow
        │  (OIDC — no stored credentials)
        ▼
AWS IAM Role (scoped to this repo only)
        │
        ├── Terraform apply → S3 bucket + CloudFront distribution
        └── aws s3 sync + cloudfront invalidation → site goes live
```

## Repo structure
```
terraform/          Infrastructure as code (S3, CloudFront, IAM/OIDC)
site/index.html      The static site the pipeline deploys
.github/workflows/    The CI/CD pipeline definition
```

## One-time setup (do this before the first push)

Terraform needs to create the OIDC trust relationship itself, so the very
first apply has to run from your own machine with your own AWS credentials —
after that, GitHub Actions takes over completely.

```bash
# 1. Install Terraform + AWS CLI if you haven't already
# 2. Configure AWS CLI once with your own IAM user/credentials
aws configure

# 3. Edit terraform/variables.tf:
#    - bucket_name: must be globally unique
#    - github_org_repo: "your-username/your-repo-name"

cd terraform
terraform init
terraform apply
# Review the plan, type yes

# 4. Copy the role ARN from the output:
terraform output github_actions_role_arn

# 5. Paste that ARN into .github/workflows/deploy.yml
#    (replace AWS_ROLE_ARN value)

# 6. Commit and push — from here on, every push deploys automatically
git add .
git commit -m "Initial infrastructure + pipeline"
git push
```

## The demo script (~9 minutes)

1. **Empty state** — show the empty AWS console + a dead URL. Nothing exists yet.
2. **Push** — trigger the pipeline, narrate over the running steps (no manual
   AWS console clicks, no stored credentials).
3. **Reveal** — refresh the console (resources exist) and the URL (site is live).
4. **Change** — edit two CSS variables at the top of `site/index.html`
   (`--deploy-version` and `--deploy-accent`) to flip the sticky banner from
   "v1.0 / blue" to "v2.0 / green."
5. **Redeploy** — push again. This run is fast (~1–2 min): it's just an S3
   sync + cache invalidation, not a full infrastructure build.
6. **Payoff** — refresh, the banner is now green and reads v2.0. One line
   changed, one push, fully automatic.

**Tip:** pre-provision the infrastructure (run steps 1–3 once before the real
presentation) so the live demo only has to show the fast content-update path.
CloudFront's first-ever creation can take 5–15 minutes, which is too slow to
sit through live.

## Teardown (avoid ongoing AWS charges)

```bash
cd terraform
terraform destroy
```
