resource "aws_nat_gateway" "this" {
  vpc_id            = aws_vpc.this.id
  availability_mode = "regional"

  tags = {
    Name = "${var.vpc_name}-regional-nat-gatway"
  }
}
