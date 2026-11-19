resource "aws_lb" "this" {
  name                       = var.name
  internal                   = var.internal
  load_balancer_type         = "application"
  security_groups            = var.security_group_ids
  subnets                    = var.subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = true
  }

  tags = {
    Name = var.name
  }
}

resource "aws_lb_target_group" "this" {
  name_prefix = var.target_group_name_prefix
  target_type = "instance"
  protocol    = "HTTP"
  port        = var.target_group_port
  vpc_id      = var.vpc_id

  health_check {
    path    = var.health_check_path
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.name
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  certificate_arn   = var.certificate_arn
  ssl_policy        = var.ssl_policy

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name = var.name
  }
}
