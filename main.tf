# AWS credentials should be loaded in the environment variables

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.AWS_REGION
}


resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_service_discovery_private_dns_namespace" "awp" {
  name        = "awp.local"
  description = "awesome project private namespace"
  vpc         = aws_vpc.main.id
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet
  availability_zone = var.availability_zone
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_eip" "ngw_eip" {
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw_eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_route_table_association" "public_igw" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private_nat" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_security_group" "server_ecs_task" {
  name   = "${var.name}-sg-server-task-${var.environment}"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol         = "tcp"
    from_port        = var.server_container_port
    to_port          = var.server_container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.name}-server-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster-${var.environment}"

  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_cloudwatch_log_group" "server_logs" {
  name = "/ecs/${var.name}-server-${var.environment}-logs"
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_cloudwatch_log_group" "client_logs" {
  name = "/ecs/${var.name}-client-${var.environment}-logs"
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

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
        environment       = var.server_container_environment
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
        environment = [
          { "name" : "SRVPORT", "value" : "5555" },
          { "name" : "SRVIP", "value" : "server.awp.local" }
        ]
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
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_service_discovery_service" "server" {
  name = "server"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.awp.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "server" {
  name                               = "${var.name}-server-service-${var.environment}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = "${var.name}-${var.environment}-server-family:${aws_ecs_task_definition.server.revision}"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.server_ecs_task.id]
    subnets          = [aws_subnet.private.id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.server.arn
  }

  depends_on = [
    aws_ecs_task_definition.server,
    aws_nat_gateway.ngw,
    aws_route_table_association.private_nat,
    aws_service_discovery_service.server
  ]
}


resource "aws_ecs_service" "client" {
  name                               = "${var.name}-client-service-${var.environment}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = "${var.name}-${var.environment}-client-family:${aws_ecs_task_definition.client.revision}"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.server_ecs_task.id]
    subnets          = [aws_subnet.private.id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  depends_on = [
    aws_ecs_task_definition.client,
    aws_nat_gateway.ngw,
    aws_route_table_association.private_nat
  ]
}
