output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.sonarqube.name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.sonarqube.arn
}

output "security_group_id" {
  description = "Security group ID of the SonarQube ECS tasks"
  value       = aws_security_group.sonarqube.id
}

output "sonarqube_url" {
  description = "URL of the SonarQube instance"
  value       = "http://${var.alb_dns_name}:9000"
} 