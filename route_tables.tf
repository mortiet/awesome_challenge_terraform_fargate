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