# golden-ami

## AMI build and EC2 Deployment

The GitHub Actions workflow runs on pushes to `main` and can also be started
manually. It builds a uniquely named AMI, extracts its ID from Packer's
`manifest.json`, and passes the ID to Terraform to create or update the EC2
instance. Terraform state is stored in S3 so later runs update the same
instance rather than creating a new one.

### One-time Terraform state setup

Create the dedicated S3 state bucket once from a machine with Terraform and AWS
credentials configured. Choose a globally unique bucket name:

```text
terraform -chdir=terraform/state-bootstrap init
terraform -chdir=terraform/state-bootstrap apply -var="state_bucket_name=<globally-unique-bucket-name>"
```

The bootstrap creates a versioned, encrypted bucket with public access blocked.
Its local state is separate from the application state; keep it safe and do not
commit it.

If `terraform/terraform.tfstate` already contains the instance state you want
to keep managing, migrate it to S3 before enabling the workflow. From the
repository root, run this command and confirm the migration when prompted:

```text
terraform -chdir=terraform init -migrate-state -backend-config="bucket=<globally-unique-bucket-name>" -backend-config="key=golden-ami/terraform.tfstate" -backend-config="region=ap-south-1" -backend-config="encrypt=true" -backend-config="use_lockfile=true"
```

Terraform 1.10 or newer is required for S3 lockfiles.

### Local SSH key setup

Generate the SSH key pair on your own machine. The private key stays local;
only the public key is passed to Terraform and stored in AWS:

```powershell
ssh-keygen -t ed25519 -f "$HOME\.ssh\golden-ami" -C "golden-ami"
Get-Content "$HOME\.ssh\golden-ami.pub"
```

In **Settings → Secrets and variables → Actions → Secrets**, add
`EC2_SSH_PUBLIC_KEY` with the complete one-line contents of
`golden-ami.pub`. This is public key material; do not upload the private file
`golden-ami`.

Terraform registers the public key in EC2, attaches it to the instance, and
allows SSH only from `223.181.76.88/32`. If your public IP changes, update
`ssh_allowed_cidr` in `terraform/main.tf` to your new address in `/32` format
and push the change before deploying again. The EC2 instance also needs an
assigned public IP and the AWS account's default VPC.

After deployment, connect from the machine holding the private key:

```powershell
ssh -i "$HOME\.ssh\golden-ami" ubuntu@<instance-public-ip>
```

### GitHub configuration

Before enabling the workflow:

1. Under **Settings → Environments**, create an environment named `ami-build`.
   Require approval from a trusted reviewer, prevent self-review, restrict
   deployments to `main`, and prevent bypassing protection rules where available.
2. Under **Settings → Collaborators**, make sure only your account has write or
   admin access. For a public repository, other users can still read and fork it;
   for a private repository, grant others read access only if you want them to
   see it.
3. Under **Settings → Rules → Rulesets**, create an active ruleset targeting
   `main`. Enable **Restrict updates** and allow only your account to bypass
   that rule, if the setting offers that option. Do not grant bypass to teams,
   apps, or other roles. Also block force pushes and branch deletion. Avoid a
   pull-request requirement if you want to push your own changes directly.
4. Under **Settings → Secrets and variables → Actions → Variables**, add
   `TF_STATE_BUCKET` with the exact bucket name created above. Add
   `AWS_AMI_BUILDS_ENABLED` with value `true` only after setup is complete.
5. Ensure the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets are
   narrowly scoped to the Packer build, EC2 deployment, and access to the state
   bucket (including S3 lockfile operations). Terraform also needs permissions
   to import/delete and describe the EC2 key pair, describe the default VPC,
   create/describe/delete the SSH security group, authorize/revoke ingress and
   egress rules, manage EC2 tags, and create/replace the EC2 instance.

Do not set the enable variable until the environment and `main` ruleset are
configured. Confirm the ruleset's bypass list carefully: anyone who can bypass
the update restriction can change `main`. GitHub settings—not the workflow
file—control repository access and branch protection.
