# Public: one route table shared by all public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.route_table_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each = {
    for k, v in var.subnets : k => v
    if v.type == "public"
  }

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.public.id
}

# Private: one route table shared by all private subnets

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.route_table_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each = {
    for k, v in var.subnets : k => v
    if v.type == "private"
  }

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.private.id
}

# Data: one route table shared by all data subnets

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.route_table_name}-data-rt"
  }
}

resource "aws_route_table_association" "data" {
  for_each = {
    for k, v in var.subnets : k => v
    if v.type == "data"
  }

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.data.id
}
