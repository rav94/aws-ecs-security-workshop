[
  {
    "name": "${container-name}",
    "image": "${repository-url}:latest",
    "memory": 512,
    "memoryReservation": 256,
    "essential": true,
    "linuxParameters": {
        "capabilities": {
            "drop": ["ALL"],
            "add": [
                "CHOWN",
                "DAC_OVERRIDE",
                "FOWNER",
                "FSETID",
                "KILL",
                "NET_BIND_SERVICE",
                "NET_RAW",
                "SETGID",
                "SETUID",
                "SYS_CHROOT"
            ]
        }
    },
    "portMappings": [
      {
        "hostPort": 0,
        "containerPort": ${container-port},
        "protocol": "tcp"
      }
    ],
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