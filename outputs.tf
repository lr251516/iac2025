# Outputs
output "nlb_dns_name" {
  description = "Load Balancer DNS to access the Application"
  value       = aws_lb.webapp_nlb.dns_name
}

output "webapp_server01_public_ip" {
  description = "webapp-server01 public IP"
  value       = aws_instance.webapp_server01.public_ip
}

output "webapp_server02_public_ip" {
  description = "webapp-server02 public IP"
  value       = aws_instance.webapp_server02.public_ip
}

output "rds_endpoint" {
  description = "RDS DB endpoint"
  value       = aws_db_instance.mysql_db.address
}