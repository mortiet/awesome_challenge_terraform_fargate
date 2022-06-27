resource "aws_route_table_association" "public_igw" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private_nat" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_route.id
}