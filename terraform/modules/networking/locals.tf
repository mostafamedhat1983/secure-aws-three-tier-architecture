# retrieve all aviliable AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# store the retrieved Azs in a local to use for AZs validation 
locals {
  available_azs = data.aws_availability_zones.available.names
}