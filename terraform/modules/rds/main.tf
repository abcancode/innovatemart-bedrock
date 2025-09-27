# terraform/modules/rds/main.tf

# Generate random passwords for databases
resource "random_password" "postgres_password" {
  length  = 16
  special = true
  # Exclude problematic characters for RDS
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "mysql_password" {
  length  = 16
  special = true
  # Exclude problematic characters for RDS
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Security group for RDS instances
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
    description     = "PostgreSQL from EKS"
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
    description     = "MySQL from EKS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

# PostgreSQL RDS Instance (for orders service)
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  # Engine configuration
  engine         = "postgres"
  engine_version = "15.8"
  instance_class = "db.t3.micro"

  # Database configuration
  db_name  = "orders"
  username = "postgres"
  password = random_password.postgres_password.result

  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Performance and monitoring
  performance_insights_enabled = false
  monitoring_interval          = 0

  # Deletion protection and final snapshot
  deletion_protection       = false
  skip_final_snapshot      = true
  delete_automated_backups = true

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
    Service     = "orders"
  }
}

# MySQL RDS Instance (for catalog service)
resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0.39"
  instance_class = "db.t3.micro"

  # Database configuration
  db_name  = "catalog"
  username = "root"
  password = random_password.mysql_password.result

  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Performance and monitoring
  performance_insights_enabled = false
  monitoring_interval          = 0

  # Deletion protection and final snapshot
  deletion_protection       = false
  skip_final_snapshot      = true
  delete_automated_backups = true

  tags = {
    Name        = "${var.project_name}-mysql"
    Environment = var.environment
    Service     = "catalog"
  }
}

# DynamoDB Table (for carts service)
resource "aws_dynamodb_table" "carts" {
  name           = "${var.project_name}-carts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "customerId-index"
    hash_key        = "customerId"
    projection_type = "ALL"
  }

  tags = {
    Name        = "${var.project_name}-carts"
    Environment = var.environment
    Service     = "carts"
  }
}

# Store database credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "postgres_credentials" {
  name        = "${var.project_name}/postgres/credentials"
  description = "PostgreSQL database credentials for orders service"

  tags = {
    Name        = "${var.project_name}-postgres-credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "postgres_credentials" {
  secret_id = aws_secretsmanager_secret.postgres_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres.username
    password = random_password.postgres_password.result
    engine   = "postgres"
    host     = aws_db_instance.postgres.endpoint
    port     = aws_db_instance.postgres.port
    dbname   = aws_db_instance.postgres.db_name
  })
}

resource "aws_secretsmanager_secret" "mysql_credentials" {
  name        = "${var.project_name}/mysql/credentials"
  description = "MySQL database credentials for catalog service"

  tags = {
    Name        = "${var.project_name}-mysql-credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "mysql_credentials" {
  secret_id = aws_secretsmanager_secret.mysql_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.mysql.username
    password = random_password.mysql_password.result
    engine   = "mysql"
    host     = aws_db_instance.mysql.endpoint
    port     = aws_db_instance.mysql.port
    dbname   = aws_db_instance.mysql.db_name
  })
}