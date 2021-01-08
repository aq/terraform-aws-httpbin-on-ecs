output "load_balancer_dns" {
    value = aws_lb.this.dns_name
}
