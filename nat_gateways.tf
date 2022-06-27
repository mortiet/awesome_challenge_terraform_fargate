resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw_eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}