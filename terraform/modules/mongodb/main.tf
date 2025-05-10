# Security Group
resource "aws_security_group" "mongodb" {
  name        = "${var.project}-${var.environment}-mongodb-sg"
  description = "Security group for MongoDB instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# DocumentDB Subnet Group
resource "aws_docdb_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-docdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# MongoDB Instance
resource "aws_docdb_cluster" "main" {
  cluster_identifier = "${var.project}-${var.environment}-mongodb"
  engine            = "docdb"
  master_username   = var.admin_username != "admin" ? var.admin_username : "mongoadmin"
  master_password   = var.mongodb_password

  db_subnet_group_name   = aws_docdb_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.mongodb.id]

  skip_final_snapshot = true

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [
      cluster_identifier,
      master_username,
      master_password,
      engine_version
    ]
  }
}

# EC2 Instance
resource "aws_instance" "mongodb" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[0]

  vpc_security_group_ids = [aws_security_group.mongodb.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Install MongoDB
              wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
              echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
              sudo apt-get update
              sudo apt-get install -y mongodb-org
              sudo systemctl start mongod
              sudo systemctl enable mongod

              # Configure MongoDB
              sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
              sudo systemctl restart mongod

              # Create admin user
              mongosh --eval '
                db = db.getSiblingDB("admin");
                db.createUser({
                  user: "${var.admin_username}",
                  pwd: "${var.mongodb_password}",
                  roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
                });
              '
              EOF

  tags = {
    Name        = "${var.project}-${var.environment}-mongodb"
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

# EBS Volume for Data
resource "aws_ebs_volume" "mongodb_data" {
  availability_zone = aws_instance.mongodb.availability_zone
  size             = var.data_volume_size
  type             = "gp3"

  tags = {
    Name        = "${var.project}-${var.environment}-mongodb-data"
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_volume_attachment" "mongodb_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mongodb_data.id
  instance_id = aws_instance.mongodb.id
}

# Variables
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the MongoDB instance"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the MongoDB instance"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 20.04 LTS
}

variable "instance_type" {
  description = "Instance type for the MongoDB instance"
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "data_volume_size" {
  description = "Size of the data volume in GB"
  type        = number
  default     = 100
}

variable "admin_username" {
  description = "Admin username for MongoDB"
  type        = string
  default     = "admin"
}

variable "mongodb_password" {
  description = "Password for MongoDB admin user"
  type        = string
  sensitive   = true
}

# Outputs
output "endpoint" {
  description = "Endpoint of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "security_group_id" {
  description = "ID of the MongoDB security group"
  value       = aws_security_group.mongodb.id
}

# IAM Roles
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project}-${var.environment}-mongodb-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.environment}-mongodb-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
  }
} 