output "nameservers" {
  value = aws_route53_zone.this.name_servers
}

output "ecr_url" {
  value = aws_ecr_repository.web.repository_url
}