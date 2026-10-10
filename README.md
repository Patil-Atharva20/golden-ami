# golden-ami
Repository created by Copilot for the user Patil-Atharva20

## AMI build workflow

The Packer workflow runs on pushes to `main` and can also be started manually.
The AWS build job is disabled unless the repository variable
`AWS_AMI_BUILDS_ENABLED` is set to `true`.

Before enabling it, configure the GitHub repository:

1. Under **Settings → Environments**, create an environment named `ami-build`.
2. Require approval from a trusted reviewer, prevent self-review, restrict
   deployments to `main`, and prevent bypassing protection rules where available.
3. Under **Settings → Collaborators**, make sure only your account has write or
   admin access. For a public repository, other users can still read and fork it;
   for a private repository, grant others read access only if you want them to
   see it.
4. Under **Settings → Rules → Rulesets**, create an active ruleset targeting
   `main`. Enable **Restrict updates** and allow only your account to bypass
   that rule, if the setting offers that option. Do not grant bypass to teams,
   apps, or other roles. Also block force pushes and branch deletion. Avoid a
   pull-request requirement if you want to push your own changes directly.
5. Under **Settings → Secrets and variables → Actions → Variables**, add
   `AWS_AMI_BUILDS_ENABLED` with the value `true`.
6. Ensure the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets are
   narrowly scoped to the permissions and regions required by the Packer build.

Do not set the enable variable until the environment and `main` ruleset are
configured. Confirm the ruleset's bypass list carefully: anyone who can bypass
the update restriction can change `main`. GitHub settings—not the workflow
file—control repository access and branch protection.
