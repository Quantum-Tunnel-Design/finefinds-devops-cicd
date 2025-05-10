output "sonarqube_url" {
  description = "URL of the SonarQube instance"
  value       = "http://${var.alb_dns_name}:9000"
}

output "security_group_id" {
  description = "ID of the SonarQube security group"
  value       = aws_security_group.sonarqube.id
}

output "task_definition_arn" {
  description = "ARN of the SonarQube task definition"
  value       = aws_ecs_task_definition.sonarqube.arn
}

output "service_name" {
  description = "Name of the SonarQube service"
  value       = aws_ecs_service.sonarqube.name
}

output "cluster_name" {
  description = "Name of the SonarQube cluster"
  value       = aws_ecs_cluster.sonarqube.name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.sonarqube.arn
} 