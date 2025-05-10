output "sonarqube_url" {
  description = "URL of the SonarQube instance"
  value       = var.sonarqube_url
}

output "security_group_id" {
  description = "ID of the SonarQube security group"
  value       = aws_security_group.main.id
}

output "task_definition_arn" {
  description = "ARN of the SonarQube task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "service_name" {
  description = "Name of the SonarQube service"
  value       = aws_ecs_service.main.name
}

output "cluster_name" {
  description = "Name of the SonarQube cluster"
  value       = aws_ecs_cluster.main.name
} 