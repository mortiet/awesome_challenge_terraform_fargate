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
    security_groups  = [aws_security_group.server.id]
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
  tags = {
    Environment = var.environment
    Project     = var.name
  }
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
    security_groups  = [aws_security_group.server.id]
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
  tags = {
    Environment = var.environment
    Project     = var.name
  }
}