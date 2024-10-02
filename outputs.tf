
# output "vpc_id" {
#   value = aws_vpc.main.id
# }

# output "public_subnets" {
#   value = aws_subnet.public_subnets[*].id
# }

# output "private_subnets" {
#   value = aws_subnet.private_subnets[*].id
# }

# output "nat_gateways" {
#   value = aws_nat_gateway.nat_gw[*].id
# }
output "rds_endpoint" {
  value = aws_db_instance.kbc_wordpress.endpoint
}

output "rds_domain" {
  value = aws_db_instance.kbc_wordpress.address
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}