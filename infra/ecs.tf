locals {
  ecs-ec2-cluster-name       = "user-api-${var.env}-ecs-ec2"
  ecs-fargate-cluster-name   = "user-api-${var.env}-ecs-fargate"
  ecs-ec2-container-port     = "8080"
  ecs-ec2-container-name     = "user-api-ec2"
  ecs-fargate-container-port = "8080"
  ecs-fargate-container-name = "user-api-fargate"
}

data "aws_ami" "ecs" { # Updates launch templates using latest AMIs as they are released
  most_recent = true # get the latest version

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-*"] # ECS optimized image
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [
    "amazon" # Only official images
  ]
}

# ECS EC2 Cluster
data "template_file" "ecs-ec2-template" {
  template = file("${path.module}/templates/ecs-ec2-user-data.sh")

  vars = {
    cluster_name = local.ecs-ec2-cluster-name
  }
}

resource "aws_ecs_cluster" "ecs-ec2-cluster" {
  name = local.ecs-ec2-cluster-name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_launch_template" "ecs-ec2-cluster-launch-template" {
  name_prefix             = "${var.env}-ecs-ec2-cluster-launch-template"
  disable_api_termination = false
  instance_type           = var.ecs-ec2-instance-type
  image_id                = data.aws_ami.ecs.id
  key_name                = aws_key_pair.generated_key.key_name
  user_data               = base64encode(data.template_file.ecs-ec2-template.rendered)
  vpc_security_group_ids  = [aws_security_group.allow-ecs-ec2-cluster.id]
  update_default_version  = true

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs-ec2-role.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs-ec2-autoscaling" {
  name                 = "${var.env}-ecs-ec2-auto-scaling"
  vpc_zone_identifier  = flatten([module.vpc.private_subnets])
  termination_policies = ["OldestInstance"]
  min_size             = 0
  max_size             = 3
  desired_capacity     = 1

  launch_template {
    id      = aws_launch_template.ecs-ec2-cluster-launch-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-ecs-ec2-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "ecs-ec2-autoscaling-target-tracking-policy" {
  name                   = "${var.env}-ecs-ec2-target-tracking-plicy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.ecs-ec2-autoscaling.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = 70.0
    disable_scale_in = true
  }
}

# ECS EC2 Task
data "template_file" "user-api-task-definition-ec2-template" {
  template = file("${path.module}/templates/userapi-ec2.json.tpl")
  vars     = {
    container-name          = local.ecs-ec2-container-name
    repository-url          = replace(aws_ecr_repository.user-api.repository_url, "https://", "")
    container-port          = local.ecs-ec2-container-port
    log-group-path          = "/ecs/ec2/user-api"
    region                  = var.aws-region
    dynamodb-table-name-arn = aws_secretsmanager_secret.dynamodb-table-name.arn
  }
}

resource "aws_ecs_task_definition" "user-api-task-definition" {
  family                = "${var.env}-user-api-ec2"
  container_definitions = data.template_file.user-api-task-definition-ec2-template.rendered
  execution_role_arn    = aws_iam_role.ecs-task-execution-role.arn
  task_role_arn         = aws_iam_role.ecs-task-role.arn
}

# ECS EC2 Service
resource "aws_ecs_service" "user-api-service-ec2" {
  name                               = "${var.env}-user-api-ec2"
  cluster                            = aws_ecs_cluster.ecs-ec2-cluster.id
  task_definition                    = aws_ecs_task_definition.user-api-task-definition.arn
  launch_type                        = "EC2"
  scheduling_strategy                = "REPLICA"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  desired_count                      = 1
  health_check_grace_period_seconds  = 100
  iam_role                           = aws_iam_role.ecs-role.arn #ARN of the IAM role that allows Amazon ECS to make calls to your load balancer on your behalf. This parameter is required if you are using a load balancer with your service, but only if your task definition does not use the awsvpc network mode. If using awsvpc network mode, do not specify this role. If your account has already created the Amazon ECS service-linked role, that role is used by default for your service unless you specify a role here.

  depends_on = [
    aws_lb.ecs-ec2-user-api-alb
  ]

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs-ec2-user-api-tg.arn
    container_name   = local.ecs-ec2-container-name
    container_port   = parseint(local.ecs-ec2-container-port, 10)
  }

  #  lifecycle {
  #    ignore_changes = [task_definition, desired_count]
  #  }
}

resource "aws_appautoscaling_target" "ecs-ec2-user-api-target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs-ec2-cluster.name}/${aws_ecs_service.user-api-service-ec2.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs-ec2-user-api-scaling-policy" {
  name               = "${var.env}-user-api-ec2"
  service_namespace  = aws_appautoscaling_target.ecs-ec2-user-api-target.service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs-ec2-user-api-target.scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs-ec2-user-api-target.resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# ECS Fargate Cluster
resource "aws_ecs_cluster" "ecs-fargate-cluster" {
  name = local.ecs-fargate-cluster-name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Fargate Task
data "template_file" "user-api-task-definition-fargate-template" {
  template = file("${path.module}/templates/userapi-fargate.json.tpl")
  vars     = {
    container-name          = local.ecs-fargate-container-name
    repository-url          = replace(aws_ecr_repository.user-api.repository_url, "https://", "")
    container-port          = local.ecs-fargate-container-port
    log-group-path          = "/ecs/fargate/user-api"
    region                  = var.aws-region
    dynamodb-table-name-arn = aws_secretsmanager_secret.dynamodb-table-name.arn
  }
}

resource "aws_ecs_task_definition" "user-api-fargate-task-definition" {
  family                   = "${var.env}-user-api-fargate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 # 1024 CPU units is the equivalent of 1 vCPU.
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  task_role_arn            = aws_iam_role.ecs-task-role.arn
  container_definitions    = data.template_file.user-api-task-definition-fargate-template.rendered
}

# ECS Fargate Service
resource "aws_ecs_service" "user-api-service-fargate" {
  name                               = "${var.env}-user-api-fargate"
  cluster                            = aws_ecs_cluster.ecs-fargate-cluster.id
  task_definition                    = aws_ecs_task_definition.user-api-fargate-task-definition.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.allow-ecs-fargate-task.id]
    subnets          = flatten([module.vpc.private_subnets])
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs-fargate-user-api-tg.arn
    container_name   = local.ecs-fargate-container-name
    container_port   = parseint(local.ecs-fargate-container-port, 10)
  }

  #  lifecycle {
  #    ignore_changes = [task_definition, desired_count]
  #  }
}

resource "aws_appautoscaling_target" "ecs-fargate-user-api-target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs-fargate-cluster.name}/${aws_ecs_service.user-api-service-fargate.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs-fargate-user-api-scaling-policy-1" {
  name               = "${var.env}-user-api-memory-utlization"
  service_namespace  = aws_appautoscaling_target.ecs-fargate-user-api-target.service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs-fargate-user-api-target.scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs-fargate-user-api-target.resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "ecs-fargate-user-api-scaling-policy-2" {
  name               = "${var.env}-user-api-cpu-utlization"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs-fargate-user-api-target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-fargate-user-api-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs-fargate-user-api-target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}