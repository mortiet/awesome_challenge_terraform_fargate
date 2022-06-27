resource "aws_eip" "ngw_eip" {
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}