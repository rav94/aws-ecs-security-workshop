resource "aws_lb" "ecs-user-api-alb" {
  name                       = "ecs-ec2-user-api-alb"
  subnets                    = flatten([module.vpc.public_subnets])
  internal                   = false
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  security_groups            = [aws_security_group.allow-ecs-cluster-alb.id]

  tags = {
    Name         = "${var.env}-ECS-StreamingApi-ALB"
    Environmnent = var.env
    Terraform    = "true"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_lb_listener" "ecs-user-api-listener" {
  load_balancer_arn = aws_lb.ecs-user-api-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-user-api-tg.arn
  }
}

resource "aws_lb_target_group" "ecs-user-api-tg" {
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
