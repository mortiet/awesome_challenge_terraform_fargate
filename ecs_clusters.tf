resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster-${var.environment}"

  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}