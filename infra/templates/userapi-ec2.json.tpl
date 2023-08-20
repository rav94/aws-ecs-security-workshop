[
  {
    "name": "${container-name}",
    "image": "${repository-url}:latest",
    "memory": 512,
    "memoryReservation": 256,
    "essential": true,
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
    }
  }
]