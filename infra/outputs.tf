output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "availability_zones" {
  description = "List of IDs of availability zones"
  value       = module.vpc.azs
}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.vpc.elasticache_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "ecs_ec2_alb" {
  description = "ECS EC2 App ALB"
  value       = aws_lb.ecs-ec2-user-api-alb.dns_name
}

output "ecs_fargate_alb" {
  description = "ECS Fargate App ALB"
  value       = aws_lb.ecs-fargate-user-api-alb.dns_name
}