resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.environment}-rds-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.ecs_security_group_id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

resource "aws_db_instance" "main" {
  identifier = "${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class      = var.instance_class
  allocated_storage   = 20
  storage_type        = "gp3"
  storage_encrypted   = true
  publicly_accessible = false

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection

  skip_final_snapshot = true
}