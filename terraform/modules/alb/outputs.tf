output "alb_arn" {
  description = "ARN of the load balancer (used by the WAF association)"
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Hosted zone ID of the load balancer (for Route 53 alias records)"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group (the ASG attaches its instances to it)"
  value       = aws_lb_target_group.this.arn
  # A target group can't take instances until a listener ties it to the load balancer.
  # Terraform can't see that link here, so make anything using this output wait for the listener.
  depends_on = [aws_lb_listener.this]
}

output "listener_arn" {
  description = "ARN of the listener"
  value       = aws_lb_listener.this.arn
}
