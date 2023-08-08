resource "aws_eip" "nat-eip" {
  count = 3

  domain = "vpc"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-${env}"
  cidr = "10.0.0.0/16"

  azs                 = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  elasticache_subnets = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
  database_subnets    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false 
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false

  reuse_nat_ips       = true                    # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.nat-eip.*.id  # <= IPs specified here as input to the module

  enable_dhcp_options = true
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_security_group" "docdb-service" {
  name        = "docdb-${var.env}"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.main-vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.main-vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.main-vpc.public_subnets
}

output "availability_zones" {
  description = "List of IDs of availability zones"
  value       = module.main-vpc.azs
}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.main-vpc.elasticache_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.main-vpc.database_subnets
}