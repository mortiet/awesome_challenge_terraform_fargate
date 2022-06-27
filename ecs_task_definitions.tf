resource "aws_ecs_task_definition" "server" {
  family                   = "${var.name}-${var.environment}-server-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode(
    [
      {
        name  = "${var.name}-container-${var.environment}"
        image = "${var.server_container_image}:latest"
        entryPoint = [
          "sh",
          "-c"
        ]
        command           = ["/bin/sh -c 'socat -d -d TCP-LISTEN:$SRVPORT,reuseaddr,pf=ipv4,fork EXEC:'/bin/echo srv-pong''"]
        cpu               = 200
        memoryReservation = 400
        essential         = true
        environment       = [{ "name" : "SRVPORT", "value" : tostring(var.server_container_port) }]

        portMappings = [
          {
            protocol      = "tcp"
            containerPort = var.server_container_port
            hostPort      = var.server_container_port
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.server_logs.name
            awslogs-region        = var.AWS_REGION
            awslogs-stream-prefix = "ecs"
          }
        }
      }
    ]
  )
  tags = {
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_ecs_task_definition" "client" {
  family                   = "${var.name}-${var.environment}-client-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode(
    [
      {
        name  = "${var.name}-container-${var.environment}"
        image = "${var.server_container_image}:latest"
        entryPoint = [
          "sh",
          "-c"
        ]
        command = [
          <<EOT
            /bin/sh -c 'while true; do if [ "x$(timeout 2 socat TCP:$SRVIP:$SRVPORT - &>/dev/null; echo $?)" == "x0" ]; then echo $(date +"[%D %H:%M:%S]") Successful TCP connetion to $SRVIP:$SRVPORT; else echo $(date +"[%D %H:%M:%S]") Failed TCP connetion to $SRVIP:$SRVPORT; fi; sleep 1; done';
            EOT
        ]
        cpu               = 256
        memoryReservation = 512
        essential         = true
        environment       = [{ "name" : "SRVPORT", "value" : tostring(var.server_container_port) }, { "name" : "SRVIP", "value" : "${aws_service_discovery_service.server.name}.${var.name}-${var.environment}.local" }]

        portMappings = [
          {
            protocol      = "tcp"
            containerPort = var.server_container_port
            hostPort      = var.server_container_port
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.client_logs.name
            awslogs-region        = var.AWS_REGION
            awslogs-stream-prefix = "ecs"
          }
        }
      }
    ]
  )
  tags = {
    Environment = var.environment
    Project     = var.name
  }
}