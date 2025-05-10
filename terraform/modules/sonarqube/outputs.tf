output "sonarqube_url" {
  description = "URL of the SonarQube server"
  value       = "http://${var.alb_dns_name}"
}

output "sonarqube_initial_password" {
  description = "Initial admin password for SonarQube"
  value       = "admin"  # Default SonarQube password
  sensitive   = true
} 