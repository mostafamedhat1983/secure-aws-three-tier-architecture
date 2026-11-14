
resource "aws_security_group" "this" {
  name        = "${var.name}-security-group"
  description = var.description
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.name}-security-group"
  }
}


resource "aws_vpc_security_group_ingress_rule" "ingress-rule" {
  security_group_id            = aws_security_group.this.id
  for_each                     = var.security-group-ingress
  ip_protocol                  = each.value.ip_protocol
  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_security_group_id
}


resource "aws_vpc_security_group_egress_rule" "egress-rule" {
  security_group_id            = aws_security_group.this.id
  for_each                     = var.security-group-egress
  cidr_ipv4                    = each.value.cidr_ipv4
  ip_protocol                  = each.value.ip_protocol
  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  referenced_security_group_id = each.value.referenced_security_group_id
}

resource "aws_default_security_group" "this" {
  vpc_id = var.vpc_id
  # no ingress or egress blocks = no rules = deny all

  tags = {
    Name = var.default-sg-name
  }
}
