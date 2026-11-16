resource "aws_cloudwatch_log_group" "error" {
  name              = "/aws/rds/instance/${var.identifier}/error"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "slowquery" {
  name              = "/aws/rds/instance/${var.identifier}/slowquery"
  retention_in_days = 30
}
