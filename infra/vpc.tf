resource "aws_eip" "nat-eip" {
  count = 1

  domain = "vpc"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-${var.env}"
  cidr = "10.0.0.0/16" # The allowed block size is between a /16 netmask (65,536 IP addresses) and /28 netmask (16 IP addresses).

  azs             = ["${var.aws-region}a", "${var.aws-region}b", "${var.aws-region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  reuse_nat_ips       = true                    # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.nat-eip.*.id  # <= IPs specified here as input to the module

  enable_dhcp_options              = true
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_security_group" "allow-ecs-ec2-cluster" {
  vpc_id      = module.vpc.vpc_id
  name        = "${var.env}-allow-ecs-ec2-cluster"
  description = "security group for ecs ec2 cluster"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 1024
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.allow-ecs-cluster-alb.id]
  }

  tags = {
    Name        = "allow-ecs-cluster"
    Terraform   = "true"
    Environment = var.env
  }

  depends_on = [
    aws_security_group.allow-ecs-cluster-alb
  ]
}

resource "aws_security_group" "allow-ecs-fargate-task" {
  vpc_id      = module.vpc.vpc_id
  name        = "${var.env}-allow-ecs-fargate-task"
  description = "security group for ecs fargate task"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port       = local.ecs-fargate-container-port
    to_port         = local.ecs-fargate-container-port
    protocol        = "tcp"
    security_groups = [aws_security_group.allow-ecs-cluster-alb.id]
  }

  tags = {
    Name        = "allow-ecs-fargate-task"
    Terraform   = "true"
    Environment = var.env
  }

  depends_on = [
    aws_security_group.allow-ecs-cluster-alb
  ]
}

resource "aws_security_group" "allow-ecs-cluster-alb" {
  vpc_id      = module.vpc.vpc_id
  name        = "${var.env}-allow-ecs-cluster-alb"
  description = "security group for ecs cluster alb"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "allow-ecs-cluster-alb"
    Terraform   = "true"
    Environment = var.env
  }
}