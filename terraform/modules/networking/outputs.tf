# ---- VPC ----
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC (handy for SG rules that reference the VPC range)"
  value       = aws_vpc.this.cidr_block
}

# ---- Subnets grouped by type (matches public / private / data route tables) ----
output "public_subnet_ids" {
  description = "Public subnet IDs, one per AZ — for the internet-facing ALB"
  value = [
    for k, s in aws_subnet.subnets : s.id
    if var.subnets[k].type == "public"
  ]
}

output "private_subnet_ids" {
  description = "Private subnet IDs, one per AZ — for the EC2 ASGs (reached via SSM)"
  value = [
    for k, s in aws_subnet.subnets : s.id
    if var.subnets[k].type == "private"
  ]
}

output "data_subnet_ids" {
  description = "Data subnet IDs, one per AZ — for the RDS subnet group"
  value = [
    for k, s in aws_subnet.subnets : s.id
    if var.subnets[k].type == "data"
  ]
}

# ---- Full keyed map (fallback when two tiers share the same type) ----
output "subnet_ids" {
  description = "Map of subnet key -> subnet ID (use when tiers need finer grouping than type)"
  value       = { for k, s in aws_subnet.subnets : k => s.id }
}

output "availability_zones" {
  description = "Distinct AZs that contain subnets (the AZs you spread across)"
  value       = distinct([for k, v in var.subnets : v.availability_zone])
}

# ---- Route tables (needed when adding VPC endpoints, peering, or a TGW) ----
output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = aws_route_table.private.id
}
output "data_route_table_id" {
  description = "ID of the data subnet route table."
  value       = aws_route_table.data.id
}

# ---- Gateways (rarely consumed, but useful for debugging / peering) ----
output "internet_gateway_id" {
  description = "ID of the VPC internet gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway."
  value       = aws_nat_gateway.this.id
}

# ---- Default SG (locked down default_security_group.tf) ----
output "default_security_group_id" {
  description = "ID of the VPC default security group (deny-all; reference it where no inbound is wanted)"
  value       = aws_default_security_group.this.id
}
