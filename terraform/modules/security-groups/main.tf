
resource "aws_security_group" "this" {
  name        = "${var.name}-security-group"
  description = "Security group for web server"
  vpc_id      = var.vpc_id
}


resource "aws_vpc_security_group_ingress_rule" "ingress-rule" {
  security_group_id = aws_security_group.this.id
  for_each          = var.security-group-ingress
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
}


resource "aws_vpc_security_group_egress_rule" "egress-rule" {
  security_group_id = aws_security_group.this.id
  for_each          = var.security-group-egress
  cidr_ipv4         = each.value.cidr_ipv4
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
}
