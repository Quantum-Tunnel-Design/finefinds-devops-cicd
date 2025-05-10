output "sonarqube_password" {
  description = "SonarQube database password"
  value       = random_password.sonarqube_password.result
  sensitive   = true
}

output "sonarqube_url" {
  description = "URL of the SonarQube instance"
  value       = "http://${aws_lb.sonarqube.dns_name}:9000"
}

output "sonarqube_initial_password" {
  description = "Initial admin password for SonarQube"
  value       = "admin"  # Default SonarQube password
  sensitive   = true
} 