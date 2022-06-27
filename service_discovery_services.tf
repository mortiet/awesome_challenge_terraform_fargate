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

  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}