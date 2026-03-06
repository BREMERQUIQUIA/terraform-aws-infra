# 🏗️ terraform-aws-infra

![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-IaC-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)
![Environments](https://img.shields.io/badge/Environments-dev%20%7C%20staging%20%7C%20prod-blue?style=for-the-badge)

> Complete AWS infrastructure deployed as Code with Terraform. Covers VPC, EC2, RDS, S3, and IAM with reusable modules for dev, staging, and production environments.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Infrastructure Components](#-infrastructure-components)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Environments](#-environments)
- [Project Structure](#-project-structure)
- [Technical Decisions](#-technical-decisions)
- [Cost Estimate](#-cost-estimate)
- [Author](#-author)

---

## 🌐 Overview

Managing infrastructure manually leads to configuration drift, human errors, and environments that are impossible to reproduce. This project solves that by defining the entire AWS infrastructure as code.

**Key outcomes:**
- Deploy a complete environment in under 5 minutes
- 100% reproducible across dev / staging / prod
- Version-controlled infrastructure changes with peer review via Pull Requests
- Estimated cost reduction of 40% vs manual provisioning due to right-sized resources

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                      │   │
│  │                                                           │   │
│  │  ┌─────────────────────┐  ┌─────────────────────────┐   │   │
│  │  │   Public Subnet      │  │    Private Subnet        │   │   │
│  │  │   10.0.1.0/24        │  │    10.0.2.0/24           │   │   │
│  │  │                      │  │                          │   │   │
│  │  │  ┌───────────────┐   │  │  ┌────────────────────┐  │   │   │
│  │  │  │  EC2 Instance  │   │  │  │   RDS (MySQL)      │  │   │   │
│  │  │  │  (Web Server)  │   │  │  │   db.t3.micro      │  │   │   │
│  │  │  └───────┬────────┘   │  │  └────────────────────┘  │   │   │
│  │  │          │             │  │                          │   │   │
│  │  └──────────┼─────────────┘  └─────────────────────────┘   │   │
│  │             │                                               │   │
│  │  ┌──────────▼──────────┐                                    │   │
│  │  │   Internet Gateway   │                                    │   │
│  │  └─────────────────────┘                                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────┐   ┌──────────────┐   ┌─────────────────────┐  │
│  │     S3        │   │     IAM       │   │   Security Groups   │  │
│  │  (Storage)    │   │  (Roles)      │   │   (Firewall)        │  │
│  └──────────────┘   └──────────────┘   └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧩 Infrastructure Components

| Component | Resource | Configuration |
|---|---|---|
| **Network** | VPC | CIDR 10.0.0.0/16, DNS enabled |
| **Subnets** | Public + Private | Multi-AZ for high availability |
| **Compute** | EC2 t3.micro | Amazon Linux 2, auto-assigned EIP |
| **Database** | RDS MySQL 8.0 | db.t3.micro, private subnet, encrypted |
| **Storage** | S3 Bucket | Versioning enabled, lifecycle policy |
| **Security** | IAM Role + SG | Least privilege, port-specific rules |
| **Gateway** | Internet Gateway | Public subnet routing |

---

## 📦 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- AWS IAM user with: `EC2FullAccess`, `RDSFullAccess`, `S3FullAccess`, `IAMFullAccess`, `VPCFullAccess`

```bash
# Verify installations
terraform --version
aws --version
aws sts get-caller-identity
```

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/BREMERQUIQUIA/terraform-aws-infra.git
cd terraform-aws-infra

# 2. Copy and edit variables
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars

# 3. Initialize Terraform
cd environments/dev
terraform init

# 4. Preview changes
terraform plan

# 5. Deploy
terraform apply

# 6. Destroy when done (avoid costs)
terraform destroy
```

---

## 🌍 Environments

| Environment | Purpose | Instance Size | Auto-shutdown |
|---|---|---|---|
| `dev` | Development & testing | t3.micro | ✅ Yes (nights/weekends) |
| `staging` | Pre-production validation | t3.small | ✅ Yes (nights) |
| `prod` | Production workloads | t3.medium | ❌ No |

Each environment has its own `terraform.tfvars` with independent state in S3.

---

## 📁 Project Structure

```
terraform-aws-infra/
├── modules/
│   ├── vpc/
│   │   ├── main.tf         # VPC, subnets, IGW, route tables
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/
│   │   ├── main.tf         # EC2 instance, security group, EIP
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf         # RDS instance, subnet group, SG
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── s3/
│       ├── main.tf         # S3 bucket, versioning, lifecycle
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   ├── staging/
│   │   └── ...
│   └── prod/
│       └── ...
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🧠 Technical Decisions

**Why separate modules per service?**
Each module (VPC, EC2, RDS, S3) is independently reusable and testable. This follows the DRY principle — changing the RDS module doesn't risk breaking network configuration.

**Why separate state per environment?**
Sharing Terraform state across environments is a common source of catastrophic mistakes (accidentally destroying prod while working on dev). Each environment has isolated state in its own S3 prefix.

**Why t3.micro for dev?**
t3.micro is free-tier eligible and sufficient for development. The module accepts `instance_type` as a variable, so scaling up for staging/prod is a one-line change.

**Why private subnet for RDS?**
Databases should never be directly accessible from the internet. The private subnet + security group combination ensures RDS is only reachable from EC2 instances within the same VPC.

---

## 💰 Cost Estimate (dev environment)

| Resource | Monthly Cost |
|---|---|
| EC2 t3.micro | ~$0 (free tier) |
| RDS db.t3.micro | ~$0 (free tier) |
| S3 storage | ~$0.01 |
| Data transfer | ~$0.01 |
| **Total** | **~$0.02/month** |

*With auto-shutdown enabled for dev, actual compute costs are near zero.*

---

## 👤 Author

**Bremer Quiquia Cirineo** — Cloud Engineer | AWS · Azure · Terraform

[![GitHub](https://img.shields.io/badge/GitHub-BREMERQUIQUIA-181717?style=flat&logo=github)](https://github.com/BREMERQUIQUIA)

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
