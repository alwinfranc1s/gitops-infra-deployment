# gitops-infra-deployment

Project 18: GitOps Infra Deployment

## Project overview

This is a small, beginner-friendly **GitOps** project. The Git repository is the
single source of truth for infrastructure: when a Pull Request is **merged into
`main`**, GitHub Actions automatically runs Terraform to deploy the change. A
human must **approve** the deployment before `terraform apply` runs.

To keep things simple (and free), the Terraform configuration does not use a
cloud provider. It uses the [`hashicorp/local`](https://registry.terraform.io/providers/hashicorp/local/latest)
provider to create a text file, which is enough to demonstrate the full
`init → validate → plan → approve → apply` flow.

```
.
├── .github/workflows/terraform-apply.yml   # GitHub Actions workflow
├── terraform/
│   ├── versions.tf                        # Terraform & provider versions
│   ├── variables.tf                       # Input variables
│   ├── main.tf                            # The resource (a local file)
│   ├── outputs.tf                         # Outputs shown after apply
│   └── .terraform.lock.hcl                # Pinned provider checksums
└── README.md
```

## Tools and prerequisites

- A GitHub repository with **GitHub Actions** enabled.
- **GitHub Environments** with required reviewers. These are available on public
  repositories, and on private repositories with a GitHub Pro, Team or
  Enterprise plan.
- Optional, for running it locally: [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5`.

No cloud account or secrets are needed.

### Run it locally (optional)

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
cat output/deployment-production.txt
```

## How the workflow operates

The workflow lives in [`.github/workflows/terraform-apply.yml`](.github/workflows/terraform-apply.yml).

1. **Trigger** – it runs on the `pull_request` event with type `closed` for the
   `main` branch. Both jobs have the condition
   `github.event.pull_request.merged == true`, so a PR that is closed without
   being merged does **not** deploy anything.
2. **`plan` job**
   - Checks out the merge commit.
   - Installs a pinned Terraform version.
   - Runs `terraform fmt -check`, `terraform init` and `terraform validate`.
   - Runs `terraform plan -out=tfplan`, adds the plan to the run summary and
     uploads the plan as an artifact.
3. **Approval gate** – the `apply` job uses `environment: production`. If the
   `production` environment has required reviewers, the job pauses until
   someone approves it.
4. **`apply` job** – after approval it downloads the saved plan and runs
   `terraform apply tfplan`. This applies **exactly** the plan that was
   reviewed, then prints the Terraform outputs and the created file.

### Security practices used

- `permissions: contents: read`: the `GITHUB_TOKEN` can only read the repository.
- `persist-credentials: false` on checkout, so the token is not left in the Git config.
- All actions are pinned to a full commit SHA.
- The Terraform version is pinned and `.terraform.lock.hcl` pins provider checksums.
- `concurrency` prevents two deployments from running at the same time.
- A manual approval is required before any change is applied.
- State, plan files and `*.tfvars` are listed in `.gitignore` so they are never committed.

> **Note:** to keep the demo simple, Terraform state is stored on the runner
> and is discarded when the job finishes. Every run therefore starts from an
> empty state. For real infrastructure, configure a
> [remote backend](https://developer.hashicorp.com/terraform/language/backend)
> (for example S3 or HCP Terraform) so that state is kept between runs.

## How to configure GitHub Environment approvals

1. In your repository, go to **Settings → Environments**.
2. Click **New environment**, name it **`production`** (it must match the
   workflow), and click **Configure environment**.
3. Check **Required reviewers** and add the users or teams that may approve
   deployments (up to 6). Optionally check **Prevent self-review**.
4. Under **Deployment branches and tags**, choose **Selected branches and tags**
   and add a rule for `main`. Then click **Save protection rules**.

> If the `production` environment does not exist, GitHub creates it on the
> first run **without** any protection rules, so the apply job would run without
> approval. Create and configure the environment first.

## How to trigger and verify a workflow run

1. Create a branch and make a change, for example edit the default `message`
   in `terraform/variables.tf`:

   ```bash
   git checkout -b update-message
   # edit terraform/variables.tf
   git commit -am "Update deployment message"
   git push -u origin update-message
   ```

2. Open a Pull Request into `main` and **merge** it.
3. Open the **Actions** tab and select the **Terraform Apply** run.
4. Check the **Terraform Plan** job. The plan is shown in the run summary.
5. The **Terraform Apply** job shows *Waiting for review*. A required reviewer
   clicks **Review deployments**, selects `production` and clicks
   **Approve and deploy**. Click **Reject** to cancel the deployment.
6. When the apply job finishes, open its logs. The **Terraform Apply** step
   shows `Apply complete! Resources: 1 added`. The **Show result** step prints
   the outputs and the content of the created file.
7. The deployment is also listed under **Deployments** on the repository's
   main page and under **Settings → Environments → production**.
