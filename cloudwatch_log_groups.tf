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