
resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_group_ids
  user_data              = base64encode(var.user_data)
  update_default_version = true

  iam_instance_profile {
    name = var.instance_profile_name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.metadata_hop_limit
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.name
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = var.name
    }
  }

  tags = {
    Name = var.name
  }
}

resource "aws_autoscaling_group" "this" {
  name                = var.name
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.target_group_arn]
  # Health checks used to decide when to replace instances:
  # "EC2" — EC2 instance checks only (default).
  # "ELB" — EC2 instance checks plus load balancer checks.
  # The load balancer health-check path is configured in the target group's health_check block (in alb module)
  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period
  default_instance_warmup   = var.default_instance_warmup
  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  lifecycle {
    precondition {
      condition = (
        var.min_size < var.max_size &&
        var.min_size <= var.desired_capacity &&
        var.desired_capacity <= var.max_size
      )

      error_message = "max_size must be greater than min_size, and desired_capacity must be between min_size and max_size."
    }
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}
