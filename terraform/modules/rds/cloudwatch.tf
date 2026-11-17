resource "aws_cloudwatch_log_group" "error" {
  name              = "/aws/rds/instance/${var.identifier}/error"
  retention_in_days = 30

  tags = {
    Name = var.cloudwatch_log_group_error_name
  }
}

resource "aws_cloudwatch_log_group" "slowquery" {
  name              = "/aws/rds/instance/${var.identifier}/slowquery"
  retention_in_days = 30

  tags = {
    Name = var.cloudwatch_log_group_slowquery_name
  }
}
