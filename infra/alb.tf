# ECS EC2 Resources
resource "aws_lb" "ecs-ec2-user-api-alb" {
  name                       = "ecs-ec2-user-api-alb"
  subnets                    = flatten([module.vpc.public_subnets])
  internal                   = false
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  security_groups            = [aws_security_group.allow-ecs-cluster-alb.id]

  tags = {
    Name        = "${var.env}-ecs-ec2-user-api-alb"
    Environment = var.env
    Terraform   = "true"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_lb_listener" "ecs-ec2-user-api-listener" {
  load_balancer_arn = aws_lb.ecs-ec2-user-api-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-ec2-user-api-tg.arn
  }
}

resource "aws_lb_target_group" "ecs-ec2-user-api-tg" {
  name        = "ecs-ec2-user-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200,202"
  }

  #  stickiness {
  #    type = "lb_cookie"
  #
  #    # Cookie Durations Default - 1 Day
  #  }
}

# ECS Fargate Resources
resource "aws_lb" "ecs-fargate-user-api-alb" {
  name                       = "ecs-fargate-user-api-alb"
  subnets                    = flatten([module.vpc.public_subnets])
  internal                   = false
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  security_groups            = [aws_security_group.allow-ecs-cluster-alb.id]

  tags = {
    Name        = "${var.env}-ecs-fargate-user-api-alb"
    Environment = var.env
    Terraform   = "true"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_lb_listener" "ecs-fargate-user-api-listener" {
  load_balancer_arn = aws_lb.ecs-fargate-user-api-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-fargate-user-api-tg.arn
  }
}

resource "aws_lb_target_group" "ecs-fargate-user-api-tg" {
  name        = "ecs-fargate-user-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200,202"
  }

  #  stickiness {
  #    type = "lb_cookie"
  #
  #    # Cookie Durations Default - 1 Day
  #  }
}

output "ecs_ec2_alb" {
  description = "ECS EC2 App ALB"
  value       = aws_lb.ecs-ec2-user-api-alb.dns_name
}

output "ecs_fargate_alb" {
  description = "ECS Fargate App ALB"
  value       = aws_lb.ecs-fargate-user-api-alb.dns_name
}
