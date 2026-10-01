# DevOps Terraform & Database Assessment

## Overview

This repository contains the complete submission for the DevOps Terraform and Database Assessment.

The project includes:

* Terraform code for AWS infrastructure design
* Separate Dev and Prod Terraform environments
* Modular Terraform configuration
* ECS Fargate with Application Load Balancer
* Private PostgreSQL RDS
* Docker Compose PostgreSQL for local development
* Database schema and seed data
* Query optimization and indexing
* PostgreSQL backup and restore scripts
* GitHub Actions for Terraform validation
* Setup and verification instructions

The Terraform configuration is provided as an infrastructure design and has not been deployed to AWS.

---

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

* ALB runs in public subnets.
* ECS Fargate tasks run in private subnets.
* RDS runs in private subnets.
* NAT Gateway provides outbound internet access for private subnets.
* RDS is not publicly accessible.

### Security Flow

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

ECS accepts traffic only from the ALB security group, and RDS accepts PostgreSQL traffic only from the ECS security group.

---

# 1. Terraform Infrastructure

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
* Encrypted storage
* Automated backup configuration
* Deletion protection

---

## Dev and Prod Configuration

Both environments use the same reusable Terraform modules with environment-specific configuration.

| Setting             | Dev           | Prod          |
| ------------------- | ------------- | ------------- |
| RDS instance        | `db.t3.micro` | `db.t3.small` |
| Backup retention    | 1 day         | 7 days        |
| Deletion protection | Disabled      | Enabled       |

### Terraform Variables

Environment-specific configuration is provided in:

```text
infra/envs/dev/dev.tfvars
infra/envs/prod/prod.tfvars
```

The RDS password currently uses:

```hcl
db_password = "change-me"
```

This is a placeholder and should be replaced with a secure secret before deployment.

---

# 2. Local PostgreSQL Database

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

### Local Database Configuration

* Database: `hotel_booking`
* Username: `admin`
* Password: `admin123`
* Port: `5432`

These credentials are used only for the local Docker PostgreSQL database.

---

# 3. Database Schema and Seed Data

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

The seed scripts create:

* 150 hotel bookings
* 150 associated booking events
* Multiple organizations
* Multiple cities
* Multiple booking statuses

---

# 4. Query Optimization

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

`EXPLAIN ANALYZE` was used to inspect query execution.

Because the test dataset contains only 150 rows, PostgreSQL may still choose a sequential scan because scanning a small table can be cheaper than using the index. The composite index is intended to improve filtering performance as the table grows.

---

# 5. Database Backup and Restore

## Backup

Backup script:

```text
scripts/backup.sh
```

Create a timestamped PostgreSQL backup:

```bash
./scripts/backup.sh
```

Backups are created in:

```text
backups/
```

Backup files are excluded from Git because they are generated database artifacts.

## Restore

Restore script:

```text
scripts/restore.sh
```

Restore a backup into a fresh database:

```bash
./scripts/restore.sh backups/<backup-file>.sql
```

The restore script creates:

```text
hotel_booking_restore
```

and restores the database contents into it.

The restored database can be verified by checking the `hotel_bookings` and `booking_events` row counts.

---

# 6. GitHub Actions

The workflow is located at:

```text
.github/workflows/terraform.yaml
```

The workflow performs:

* Terraform format check
* Terraform initialization
* Terraform validation

It runs for Terraform-related changes and does not deploy infrastructure.

---

# 7. Terraform State

Separate backend configurations are provided for Dev and Prod.

```text
Dev  → dev/terraform.tfstate
Prod → prod/terraform.tfstate
```

The backend configuration uses an S3 backend design.

A real S3 state bucket must be configured before deployment.

Terraform state files and local Terraform directories are excluded from Git.

---

# 8. Security Considerations

* RDS is private and not publicly accessible.
* RDS access is restricted to the ECS security group.
* ECS access is restricted to the ALB security group.
* RDS storage encryption is enabled.
* Production RDS has deletion protection enabled.
* Terraform state files are excluded from Git.
* Generated database backup files are excluded from Git.
* Database credentials are provided through Terraform variables.
* The submitted RDS password is only a placeholder.

---

# 9. Verification

### Terraform

```bash
terraform fmt
terraform init
terraform validate
terraform plan -refresh=false
```

### Database

```bash
docker compose up
```

### Backup

```bash
./scripts/backup.sh
```

### Restore

```bash
./scripts/restore.sh backups/<backup-file>.sql
```

The repository is structured so that the Terraform configuration, database setup, SQL scripts, and backup/restore functionality can be reviewed independently.

---

# 10. Submission Contents

```text
.github/workflows/terraform.yaml
.gitignore
README.md
docker-compose.yaml

infra/
├── envs/
│   ├── dev/
│   └── prod/
└── modules/
    ├── network/
    ├── ecs/
    └── rds/

scripts/
├── backup.sh
└── restore.sh

sql/
├── schema.sql
├── seed.sql
└── seed_events.sql
```

## Maintainer

**Shreyansh Bhalla**
