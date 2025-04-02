output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block da VPC criada"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private.*.id
}

output "default_security_group_id" {
  description = "ID do grupo de segurança padrão"
  value       = aws_security_group.default.id
}

output "nat_gateway_ip" {
  description = "IP do NAT Gateway (se criado)"
  value       = var.create_nat_gateway ? aws_eip.nat[0].public_ip : null
}