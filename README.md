# Session 4 — Demo 3: RDS Postgres Module

Build a reusable Terraform module that provisions a production-ready Postgres database on AWS RDS, wiring together a security group, subnet group, parameter group, and DB instance.

## What students learn

- How Terraform's dependency graph handles resource ordering when multiple resources reference each other
- Why `sensitive = true` on a variable omits its value from plan output — and why the credential still lives in `terraform.tfstate`
- Why the ingress rule on port 5432 is locked to a private CIDR (`172.31.16.0/20`) instead of `0.0.0.0/0`
- Why an explicit `aws_db_subnet_group` is required — without it, RDS falls back to the default VPC, which may not exist
- How `aws_db_parameter_group` lets you tune Postgres settings without SSH access to the instance
- Why `storage_encrypted = true` and `backup_retention_period = 7` are baseline production settings

## Project structure

```
.
├── main.tf                        # root module — calls the rds-postgres module
├── variables.tf                   # root-level input variables
├── provider.tf                    # AWS provider configuration
├── envs/
│   └── dev/
│       └── dev.tfvars             # dev environment values (no password)
└── modules/
    └── rds-postgres/
        ├── main.tf                # security group, subnet group, parameter group, db_instance
        ├── variables.tf           # module input variables
        └── outputs.tf             # endpoint, db_name, arn
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with credentials that can create RDS resources
- A VPC with at least two private subnets in different AZs

## Demo workflow

### 1. Explore the module structure

```bash
tree .
```

### 2. Review the module variables

Open `modules/rds-postgres/variables.tf`. Notice that `db_password` has `sensitive = true` — this prevents the value from appearing in plan output and logs.

### 3. Review the module resources

Open `modules/rds-postgres/main.tf`. The four resources must be provisioned in this dependency order, which Terraform resolves automatically from the references:

1. `aws_security_group.rds` — allows ingress on port 5432 from the private network
2. `aws_db_subnet_group.this` — tells RDS which AZs it can use
3. `aws_db_parameter_group.this` — Postgres 16 parameter group for runtime tuning
4. `aws_db_instance.this` — the database instance, referencing all three above

### 4. Set the database password via environment variable

Never hardcode credentials. Pass the password through an environment variable:

```bash
export TF_VAR_db_password=YourSecurePassword123
```

### 5. Initialize Terraform

```bash
terraform init
```

### 6. Plan the deployment

```bash
terraform plan -var-file=envs/dev/dev.tfvars
```

Expected output:

```
Plan: 4 to add, 0 to change, 0 to destroy.
```

### 7. Apply

RDS provisioning takes 5–10 minutes. The apply command will block until the instance is ready.

```bash
terraform apply -var-file=envs/dev/dev.tfvars -auto-approve
```

Expected output (once complete):

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

arn      = "arn:aws:rds:us-west-2:YOUR_ACCOUNT_ID:db:dev-blog-db"
db_name  = "blog_db"
endpoint = "dev-blog-db.XXXXXXXXXX.us-west-2.rds.amazonaws.com:5432"
```

> **Note:** `YOUR_ACCOUNT_ID` and the hostname suffix will reflect your actual AWS account.

### 8. Clean up

```bash
terraform destroy -var-file=envs/dev/dev.tfvars -auto-approve
```

## Expected outcomes

By the end of this demo, students should be able to:

1. Write a multi-resource Terraform module where resources reference each other, letting Terraform resolve provisioning order automatically
2. Explain why `sensitive = true` alone does not protect a credential — state encryption is also required
3. Configure a security group that restricts database access to private network traffic only
4. Explain the role of `aws_db_subnet_group` and `aws_db_parameter_group` in a production RDS deployment
5. Identify which RDS settings enable encryption at rest and automated backups
