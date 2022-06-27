resource "aws_service_discovery_private_dns_namespace" "awp" {
  name        = "${var.name}-${var.environment}.local"
  description = "awesome project private namespace"
  vpc         = aws_vpc.main.id
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}