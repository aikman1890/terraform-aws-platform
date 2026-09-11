# Terraform AWS Platform

Production-grade, reusable Terraform for a standard AWS platform: a hand-rolled
3-AZ VPC, a private-worker EKS cluster with IRSA, per-environment sizing, and
remote state. Built from patterns I've used across Verizon, IBM, and NTT Data
engagements — the same shape that cut environment spin-up time ~60% by making
dev and prod the same code with different knobs.

## What it deploys

- **VPC** (modules/vpc): /16 VPC, public + private subnets across 3 AZs, NAT
  gateways (single shared for dev, one per AZ for prod), dedicated route tables,
  VPC flow logs → CloudWatch Logs.
- **EKS** (modules/eks): cluster with full control-plane logging, IRSA (OIDC
  provider), two managed node groups (tainted `system` pool for addons +
  `workload` pool for apps), IMDSv2-enforced + encrypted-root launch templates,
  and the `aws-ebs-csi-driver` addon backed by an IRSA role.
- **Example** (examples/s3-iam): private S3 bucket (versioning, SSE-S3,
  TLS-only policy, lifecycle tiering) plus a least-privilege IAM role a pod can
  assume via IRSA — no static AWS keys.

## Architecture

```
                         ┌──────────────────────────────┐
                         │          Internet            │
                         └──────────────┬───────────────┘
                                        │
                              ┌─────────▼─────────┐
                              │  ALB (public      │
                              │  subnets, 3 AZs)  │
                              └─────────┬─────────┘
                                        │
      ┌─────────────────────────────────┼─────────────────────────────────┐
      │ VPC 10.x.0.0/16                 │                                 │
      │                                 ▼                                 │
      │                    ┌────────────────────────┐                     │
      │                    │  EKS worker nodes      │                     │
      │                    │  (private subnets,     │                     │
      │                    │   system + workload    │                     │
      │                    │   node groups)         │                     │
      │                    └────┬─────────┬─────────┘                     │
      │                         │         │                               │
      │              ┌──────────▼──┐ ┌────▼──────────┐  ┌──────────────┐  │
      │              │ RDS (private│ │ S3 (private   │  │ NAT gateways │  │
      │              │ subnets)    │ │ bucket, IRSA) │  │ (egress for  │  │
      │              └─────────────┘ └───────────────┘  │  private     │  │
      │                                                │  subnets)    │  │
      └────────────────────────────────────────────────┴──────────────┘──┘
```

(RDS isn't provisioned by this repo — private subnets and security-group hooks
are ready for it; the diagram shows the intended end state.)

## Prerequisites

- Terraform >= 1.5
- AWS CLI v2 with credentials for an account that can create IAM/VPC/EKS
- An S3 bucket + DynamoDB table for remote state (one-time bootstrap; the
  commands are in `envs/dev/backend.tf`)
- `kubectl` if you want to talk to the cluster after apply

## Quickstart

```bash
# 1. Fill in your real state bucket/table in the backend file
vim envs/dev/backend.tf   # replace REPLACE_ME-terraform-state / REPLACE_ME-terraform-locks

# 2. Deploy dev
cd envs/dev
terraform init
terraform plan -out dev.tfplan
terraform apply dev.tfplan

# 3. Talk to the cluster
aws eks update-kubeconfig --name platform-dev --region us-east-1
kubectl get nodes

# 4. Deploy prod the same way
cd ../prod
terraform init
terraform plan -out prod.tfplan
terraform apply prod.tfplan
```

Copy `terraform.tfvars` per engineer and keep secrets out of git (the
`.gitignore` already excludes `*.tfvars` — the committed ones are safe
examples).

## Module inputs

### modules/vpc

| Input | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix for all resources |
| `vpc_cidr` | string | — | VPC CIDR, must be /16 or larger |
| `az_count` | number | `3` | AZs to span (2–6) |
| `single_nat_gateway` | bool | `false` | One shared NAT GW (dev) vs one per AZ (prod) |
| `enable_flow_logs` | bool | `true` | VPC flow logs → CloudWatch Logs |
| `flow_logs_retention_days` | number | `90` | Flow log retention |
| `flow_logs_kms_key_id` | string | `null` | Optional KMS key for the log group |
| `tags` | map(string) | `{}` | Tags on every resource |

Outputs: `vpc_id`, `vpc_cidr`, `public_subnet_ids`, `private_subnet_ids`,
`nat_gateway_ids`, `flow_log_group_name`.

### modules/eks

| Input | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | string | — | EKS cluster name / resource prefix |
| `kubernetes_version` | string | `"1.30"` | Kubernetes version |
| `vpc_id` | string | — | VPC ID |
| `private_subnet_ids` | list(string) | — | Private subnets for nodes + control plane ENIs |
| `endpoint_public_access` | bool | `true` | Public API endpoint |
| `endpoint_public_access_cidrs` | list(string) | `["0.0.0.0/0"]` | CIDRs allowed on the public endpoint |
| `cluster_log_types` | list(string) | all five | Control-plane logs to CloudWatch |
| `enable_irsa` | bool | `true` | Create the OIDC provider for IRSA |
| `enable_ebs_csi_driver` | bool | `true` | Install aws-ebs-csi-driver with IRSA role |
| `ebs_csi_driver_version` | string | `"v1.32.0-eksbuild.1"` | Addon version |
| `system_instance_types` | list(string) | `["t3.medium"]` | System pool instance types |
| `system_desired/min/max_size` | number | `2/2/3` | System pool scaling |
| `workload_instance_types` | list(string) | `["m5.large"]` | Workload pool instance types |
| `workload_capacity_type` | string | `"ON_DEMAND"` | `ON_DEMAND` or `SPOT` |
| `workload_desired/min/max_size` | number | `3/2/10` | Workload pool scaling |
| `node_volume_size` | number | `50` | Encrypted gp3 root volume (GiB) |
| `tags` | map(string) | `{}` | Tags on every resource |

Outputs: `cluster_name`, `cluster_endpoint`, `cluster_ca_certificate`
(sensitive), `cluster_version`, `oidc_provider_arn`, `oidc_provider_url`,
`node_role_arn`, `cluster_security_group_id`.

## Dev vs prod differences

| | dev | prod |
|---|---|---|
| NAT gateways | 1 shared | 1 per AZ |
| System pool | t3.medium, 2 nodes | m5.large, 3 nodes |
| Workload pool | t3.medium SPOT, 1–6 | m5.large ON_DEMAND, 3–12 |
| API endpoint CIDRs | open | restricted (set yours in tfvars) |
| State key | `platform/dev/terraform.tfstate` | `platform/prod/terraform.tfstate` |

## Notes

- The VPC module is hand-written from raw resources, not a wrapper around
  `terraform-aws-modules/vpc` — pinning an upstream module version is shown in
  `versions.tf` style, but owning the subnet/NAT/route-table logic keeps `plan`
  output readable and upgrades boring.
- Adding a third environment is a copy of `envs/dev` with new tfvars and a new
  backend key.
- Backend blocks can't use variables — that's a Terraform limitation, not a
  repo bug. The `REPLACE_ME-*` values are the only per-account edits needed.
