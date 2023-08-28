[
  {
    "name": "${container-name}",
    "image": "${repository-url}:latest",
    "essential": true,
    "privileged": false,
    "portMappings": [
      {
        "hostPort": ${container-port},
        "containerPort": ${container-port},
        "protocol": "tcp"
      }
    ],
    "linuxParameters": {
        "capabilities": {
            "add": [
                "SYS_PTRACE"
            ]
        }
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group": "true",
        "awslogs-group": "${log-group-path}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "secrets": [
        {
            "name": "dynamodb-table-name",
            "valueFrom": "${dynamodb-table-name-arn}"
        }
    ],
    "environment": [
        {
            "name": "default-region",
            "value": "${region}"
        }
    ]
  }
]