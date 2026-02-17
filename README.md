# terraform-backend-aws

CloudFormation stack for provisioning a production-ready Terraform remote backend on AWS.

This repository creates:

- An S3 bucket for Terraform state storage
- A DynamoDB table for state locking
- Versioning, encryption, and public access protections
- Point-in-time recovery (PITR) for DynamoDB
- Retention protection to prevent accidental deletion

This stack is intended to be deployed once per AWS account (or per environment)
and then consumed by Terraform projects as their remote backend.

---

# Architecture

## S3 State Bucket

- Globally unique bucket name (parameterized)
- Versioning enabled (state rollback capability)
- Server-side encryption (AES256)
- Public access fully blocked
- DeletionPolicy: Retain

## DynamoDB Lock Table

- PAY_PER_REQUEST billing mode
- Partition key: LockID (String)
- Point-in-time recovery enabled
- Server-side encryption enabled
- DeletionPolicy: Retain

---

# Repository Structure

```
terraform-backend-aws/
├── templates/
│   └── backend.yaml
├── environments/
│   ├── dev.env
│   └── prod.env
├── scripts/
│   └── deploy.sh
└── README.md
```

- `templates/backend.yaml` – CloudFormation template defining backend infrastructure
- `environments/*.env` – Environment-specific configuration values
- `scripts/deploy.sh` – CLI wrapper for deploying the stack

---

# Deployment

## Prerequisites

- AWS CLI configured with appropriate credentials
- Permission to create S3 and DynamoDB resources

## 1. Configure Environment

Example `environments/dev.env`:

```
STACK_NAME=terraform-backend-dev
BUCKET_NAME=my-org-terraform-state-dev-123456789012
LOCK_TABLE_NAME=terraform-locks-dev
AWS_REGION=us-east-1
```

## 2. Deploy

```
./scripts/deploy.sh environments/dev.env
```

This will execute:

```shell
aws cloudformation deploy \
  --template-file templates/backend.yaml \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --parameter-overrides \
    BucketName="$BUCKET_NAME" \
    LockTableName="$LOCK_TABLE_NAME"
```

---

# Using This Backend in Terraform

Example Terraform backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-org-terraform-state-dev-123456789012"
    key            = "dev/network.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-dev"
    encrypt        = true
  }
}
```

Each Terraform project must use a unique `key` within the bucket.

---

# Design Principles

- Separation of concerns: CloudFormation manages foundational backend infrastructure.
- Terraform consumes the backend but does not manage it.
- Backend resources are retained even if the stack is deleted.
- The stack is intentionally minimal and focused.

---

# Disaster Recovery Notes

- S3 versioning enables recovery of previous Terraform state versions.
- DynamoDB PITR enables recovery of lock table data.
- DeletionPolicy: Retain prevents accidental destruction of backend infrastructure.

---

# Scope

This repository manages only Terraform backend infrastructure.
It does not manage application or workload infrastructure.
