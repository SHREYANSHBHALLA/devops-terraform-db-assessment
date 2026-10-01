# DevOps Terraform & Database Assessment

## Overview

This project implements a DevOps assessment covering:

* AWS infrastructure design using Terraform
* Modular Terraform structure for Dev and Prod
* ECS Fargate with Application Load Balancer
* Private PostgreSQL RDS
* Docker Compose PostgreSQL for local development
* SQL schema and seed data
* Query optimization using indexes
* PostgreSQL backup and restore
* Terraform validation using GitHub Actions

## Architecture

```text
Internet
   |
   v
Application Load Balancer
   |
   v
ECS Fargate
(Nginx container)
   |
   v
RDS PostgreSQL
```

### Network Design

* ALB is deployed in public subnets.
* ECS Fargate tasks run in private subnets.
* RDS runs in private subnets.
* NAT Gateway provides outbound internet access for private subnets.
* RDS is not publicly accessible.

### Security Groups

```text
Internet
   |
   | HTTP :80
   v
ALB Security Group
   |
   | HTTP :80
   v
ECS Security Group
   |
   | PostgreSQL :5432
   v
RDS Security Group
```

ECS accepts traffic only from the ALB, and RDS accepts PostgreSQL traffic only from ECS.

---

## Terraform Structure

```text
infra/
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── dev.tfvars
│   │   └── backend.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── prod.tfvars
│       └── backend.tf
│
└── modules/
    ├── network/
    ├── ecs/
    └── rds/
```

### Network Module

Creates:

* VPC
* Public and private subnets
* Internet Gateway
* NAT Gateway
* Route tables
* Subnet associations

### ECS Module

Creates:

* ECS cluster
* Fargate task definition
* ECS service
* Application Load Balancer
* Target group
* Security groups
* ECS task execution IAM role
* Nginx container

### RDS Module

Creates:

* PostgreSQL RDS instance
* DB subnet group
* RDS security group
* Storage encryption
* Automated backup configuration
* Deletion protection

---

## Dev and Prod

Both environments use the same reusable Terraform modules with environment-specific configuration.

| Setting             | Dev           | Prod          |
| ------------------- | ------------- | ------------- |
| RDS instance        | `db.t3.micro` | `db.t3.small` |
| Backup retention    | 1 day         | 7 days        |
| Deletion protection | Disabled      | Enabled       |

---

## Local PostgreSQL

PostgreSQL is provided through Docker Compose.

Start the database:

```bash
docker compose up -d
```

Check the container:

```bash
docker ps
```

Connect to PostgreSQL:

```bash
docker exec -it hotel-postgres psql -U admin -d hotel_booking
```

---

## Database

SQL files are located in:

```text
sql/
├── schema.sql
├── seed.sql
└── seed_events.sql
```

### `hotel_bookings`

Stores:

* Booking ID
* Organization ID
* City
* Booking status
* Amount
* Creation timestamp

### `booking_events`

Stores:

* Event ID
* Booking ID
* Event type
* JSONB event data
* Creation timestamp

The seed scripts populate the database with 150 bookings and associated booking events.

---

## Query Optimization

The assessment query is:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

A composite index was added:

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
ON hotel_bookings (city, created_at);
```

`EXPLAIN ANALYZE` was used to compare query execution before and after the index.

Because the test dataset contains only 150 rows, PostgreSQL may still choose a sequential scan because scanning a small table can be cheaper than using the index. The index is intended to provide better filtering performance as the table grows.

---

## Backup and Restore

Backup script:

```text
scripts/backup.sh
```

Create a timestamped PostgreSQL backup:

```bash
./scripts/backup.sh
```

Backups are stored in:

```text
backups/
```

The backup can be restored into a fresh PostgreSQL database using `psql`.

---

## Terraform Validation

Format Terraform:

```bash
terraform fmt -recursive
```

Validate Dev:

```bash
cd infra/envs/dev
terraform init -backend=false
terraform validate
```

Validate Prod:

```bash
cd infra/envs/prod
terraform init -backend=false
terraform validate
```

Both environments have been validated successfully.

---

## GitHub Actions

The workflow is located at:

```text
.github/workflows/terraform.yml
```

The workflow performs:

* Terraform format check
* Terraform initialization
* Terraform validation

It runs for Terraform-related changes and does not deploy infrastructure.

---

## Terraform State

Separate backend configurations are provided for Dev and Prod.

```text
Dev  → dev/terraform.tfstate
Prod → prod/terraform.tfstate
```

The backend configuration is included as part of the infrastructure design. A real AWS S3 backend must be configured before deployment.

---

## Security Considerations

* RDS is configured as private and is not publicly accessible.
* RDS access is restricted to the ECS security group.
* ECS access is restricted to the ALB security group.
* Database credentials are stored in environment-specific `.tfvars` files and excluded from Git using `.gitignore`.
* Terraform state files are excluded from Git.
* Production RDS has deletion protection enabled.
* Storage encryption is enabled for RDS.

---

## AWS Deployment

AWS deployment is intentionally not performed for this assessment.

The Terraform configuration provides the infrastructure design and can be deployed after configuring:

1. AWS credentials
2. A real S3 Terraform backend
3. Secure database credentials

No AWS infrastructure is created as part of the current submission.
