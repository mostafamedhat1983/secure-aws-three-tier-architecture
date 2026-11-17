resource "aws_db_instance" "this" {
  identifier                  = var.identifier
  multi_az                    = var.multi_az
  allocated_storage           = var.allocated_storage
  storage_type                = var.storage_type
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = var.security_group_ids
  storage_encrypted           = true
  publicly_accessible         = false
  db_name                     = var.db_name
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  username                    = var.username
  manage_master_user_password = true
  parameter_group_name        = aws_db_parameter_group.this.name
  skip_final_snapshot         = false
  final_snapshot_identifier   = var.final_snapshot_identifier
  copy_tags_to_snapshot       = true
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  maintenance_window          = var.maintenance_window
  backup_retention_period     = var.backup_retention_period
  enabled_cloudwatch_logs_exports = [
    "error",
    "slowquery"
  ]
  # Log groups must exist before RDS so they get our retention and are destroyed with the stack.
  # If RDS creates them first, they never expire and Terraform fails with ResourceAlreadyExistsException.
  depends_on = [
    aws_cloudwatch_log_group.error,
    aws_cloudwatch_log_group.slowquery,
  ]

  tags = {
    Name = var.rds_name
  }
}

resource "aws_db_subnet_group" "this" {
  name       = var.subnet_group_name
  subnet_ids = var.subnet_ids

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_parameter_group" "this" {
  name_prefix = var.db_parameter_group_name_prefix
  family      = var.db_parameter_group_family

  parameter {
    name  = "require_secure_transport"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }


  lifecycle {
    create_before_destroy = true
  }
}
