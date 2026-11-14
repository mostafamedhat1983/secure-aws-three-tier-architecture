resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  # no ingress or egress blocks = no rules = deny all

  tags = {
    Name = var.default-sg-name
  }
}
