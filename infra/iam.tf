# ECS EC2 role - Only EC2 entity can assume this role
resource "aws_iam_role" "ecs-ec2-role" {
  name               = "${var.env}-ecs-ec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "ecs-ec2-role" {
  name = "${var.env}-ecs-ec2-role"
  role = aws_iam_role.ecs-ec2-role.name
}

resource "aws_iam_role_policy" "ecs-ec2-role-policy" {
  name   = "${var.env}-ecs-ec2-role-policy"
  role   = aws_iam_role.ecs-ec2-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ecs:CreateCluster",
              "ecs:DeregisterContainerInstance",
              "ecs:DiscoverPollEndpoint",
              "ecs:Poll",
              "ecs:RegisterContainerInstance",
              "ecs:StartTelemetrySession",
              "ecs:Submit*",
              "ecs:StartTask",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ecs-ec2-attach-1" {
  role       = aws_iam_role.ecs-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecs-ec2-attach-2" {
  role       = aws_iam_role.ecs-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ECS Service Role for providing Load Balancer Capabilities for ECS on EC2 - ECS services - Only ECS entity can assume this role
resource "aws_iam_role" "ecs-role" {
  name = "${var.env}-ecs-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ecs-service-attach-1" {
  role       = aws_iam_role.ecs-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# ECS Task Role - Only ECS task entity can assume this role
resource "aws_iam_role" "ecs-task-role" {
  name               = "${var.env}-ecs-task-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "ecs-task-dynamodb-policy" {
  name = "${var.env}-ecs-task-dynamodb-polcy"
  role = aws_iam_role.ecs-task-role.id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:Query",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:ConditionCheckItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": [
        "arn:aws:dynamodb:${var.aws-region}:${var.aws-account-id}:table/UsersTable-${var.env}"
      ]
    }
  ]
}
EOF

}

# ECS Task Execution Role And Attachments - Only ECS task entity can assume this role
resource "aws_iam_role" "ecs-task-execution-role" {
  name               = "${var.env}-ecs-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-attach-1" {
  role       = aws_iam_role.ecs-task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs-task-cloudwatch-policy" {
  name   = "${var.env}-ecs-task-cloudwatch-polcy"
  role   = aws_iam_role.ecs-task-execution-role.id
  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs-task-secrets-manager-policy" {
  name   = "${var.env}-ecs-tasks-secrets-manager-policy"
  role   = aws_iam_role.ecs-task-execution-role.id
  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:${var.aws-region}:${var.aws-account-id}:secret:DynamoDB*"
      ]
    }
  ]
}
EOF
}