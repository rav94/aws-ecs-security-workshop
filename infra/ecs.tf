locals {
  ecs-ec2-cluster-name = "user-api-${var.env}-ecs-ec2"
  ecs-fargate-cluster-name = "user-api-${var.env}-fargate-ec2"
}

data "aws_ami" "ecs" {
  most_recent = true # get the latest version

  filter {
    name = "name"
    values = ["amzn2-ami-ecs-*"] # ECS optimized image
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = [
    "amazon" # Only official images
  ]
}

data "template_file" "ecs-ec2-template" {
  template = file("${path.module}/templates/ecs-ec2-user-data.sh")

  vars = {
    cluster_name = local.ecs-ec2-cluster-name
  }
}

resource "aws_ecs_cluster" "ecs-ec2-cluster" {
  name    = local.ecs-ec2-cluster-name

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
  user_data               = base64encode(data.template_file.ecs-ec2-cluster.rendered)
  vpc_security_group_ids  = [aws_security_group.allow-ecs-cluster.id]
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
  desired_capacity     = 0

  launch_template {
    id      = aws_launch_template.ecs-ec2-cluster-launch-template.id
    version = "$Latest"
  }

  tag {
    Name                = "${var.env}-ecs-ec2-cluster-asg"
    propagate_at_launch = true
    Terraform           = "true"
    Environment         = var.env
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

    target_value = 70.0
    disable_scale_in = true
  }
}