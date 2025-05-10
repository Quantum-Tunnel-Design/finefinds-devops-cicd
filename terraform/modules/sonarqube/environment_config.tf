locals {
  environment_configs = {
    prod = {
      task_cpu         = 2048
      task_memory      = 4096
      db_instance_class = "db.t3.medium"
      multi_az         = true
      backup_retention = 30
      quality_gate     = {
        coverage_threshold = 80
        duplication_threshold = 3
        critical_issues = 0
        blocker_issues = 0
      }
    }
    staging = {
      task_cpu         = 1024
      task_memory      = 2048
      db_instance_class = "db.t3.small"
      multi_az         = false
      backup_retention = 14
      quality_gate     = {
        coverage_threshold = 70
        duplication_threshold = 5
        critical_issues = 1
        blocker_issues = 0
      }
    }
    dev = {
      task_cpu         = 512
      task_memory      = 1024
      db_instance_class = "db.t3.micro"
      multi_az         = false
      backup_retention = 7
      quality_gate     = {
        coverage_threshold = 60
        duplication_threshold = 7
        critical_issues = 2
        blocker_issues = 1
      }
    }
    qa = {
      task_cpu         = 512
      task_memory      = 1024
      db_instance_class = "db.t3.micro"
      multi_az         = false
      backup_retention = 7
      quality_gate     = {
        coverage_threshold = 60
        duplication_threshold = 7
        critical_issues = 2
        blocker_issues = 1
      }
    }
    sandbox = {
      task_cpu         = 512
      task_memory      = 1024
      db_instance_class = "db.t3.micro"
      multi_az         = false
      backup_retention = 7
      quality_gate     = {
        coverage_threshold = 60
        duplication_threshold = 7
        critical_issues = 2
        blocker_issues = 1
      }
    }
  }

  config = local.environment_configs[var.environment]
} 