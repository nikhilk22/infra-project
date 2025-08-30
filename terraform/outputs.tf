output "alb_dns" {
  value = aws_lb.devops_alb.dns_name
}

output "server_ips" {
  value = [for s in aws_instance.devops_servers : s.public_ip]
}
