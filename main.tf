provider "aws" {
  region  = "us-west-2"
  profile = "rozaydin"
}

resource "aws_eip" "nat" {
  count = length(var.public_subnets)
  vpc   = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "Apollo"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "apollo"
  cidr = "10.58.0.0/16"

  azs             = var.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs


  enable_nat_gateway  = true
  reuse_nat_ips       = true
  external_nat_ip_ids = aws_eip.nat.*.id

  # TODO
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "Apollo"
  }
}
