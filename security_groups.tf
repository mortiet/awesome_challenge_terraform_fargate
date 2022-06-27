resource "aws_security_group" "general" {
  name   = "${var.name}-sg-general-${var.environment}"
  vpc_id = aws_vpc.main.id

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "sg-${var.name}-general-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}

resource "aws_security_group" "server" {
  name   = "${var.name}-sg-server-${var.environment}"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = var.server_container_port
    to_port     = var.server_container_port
    cidr_blocks = [var.cidr]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "sg-${var.name}-server-${var.environment}"
    Environment = var.environment
    Project     = var.name
  }
}