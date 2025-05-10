# Data source for existing EC2 instance
data "aws_instance" "existing_mongodb" {
  count = var.use_existing_instance ? 1 : 0
  filter {
    name   = "tag:Name"
    values = ["${var.project}-${var.environment}-mongodb"]
  }
}

# Get MongoDB password from Secrets Manager
data "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id = var.mongodb_password_arn
}

# Security Group
resource "aws_security_group" "mongodb" {
  count       = (var.use_existing_cluster || var.use_existing_instance) ? 0 : 1
  name        = "${var.project}-${var.environment}-mongodb-sg"
  description = "Security group for MongoDB instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Allow from VPC CIDR
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

  lifecycle {
    create_before_destroy = true
  }
}

# DocumentDB Subnet Group
resource "aws_docdb_subnet_group" "main" {
  count      = var.use_existing_subnet_group ? 0 : 1
  name       = "${var.project}-${var.environment}-docdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    ignore_changes = [name]
    prevent_destroy = true
  }
}

# Use existing or new subnet group
locals {
  subnet_group_name = var.use_existing_subnet_group ? "${var.project}-${var.environment}-docdb-subnet-group" : aws_docdb_subnet_group.main[0].name
  security_group_id = var.use_existing_cluster ? var.existing_security_group_id : (var.use_existing_instance ? var.existing_instance_security_group_id : aws_security_group.mongodb[0].id)
  mongodb_password  = jsondecode(data.aws_secretsmanager_secret_version.mongodb_password.secret_string)
}

# MongoDB Instance (DocumentDB)
resource "aws_docdb_cluster" "main" {
  count              = (var.use_existing_cluster || var.use_existing_instance) ? 0 : 1
  cluster_identifier = "${var.project}-${var.environment}-docdb"
  engine            = "docdb"
  master_username   = var.admin_username
  master_password   = local.mongodb_password
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.mongodb[0].id]
  db_subnet_group_name   = aws_docdb_subnet_group.main[0].name

  tags = {
    Name        = "${var.project}-${var.environment}-docdb"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instance for MongoDB
resource "aws_instance" "mongodb" {
  count         = (var.use_existing_cluster || var.use_existing_instance) ? 0 : 1
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[0]

  vpc_security_group_ids = [local.security_group_id]

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
  count             = (var.use_existing_cluster || var.use_existing_instance) ? 0 : 1
  availability_zone = aws_instance.mongodb[0].availability_zone
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
  count        = (var.use_existing_cluster || var.use_existing_instance) ? 0 : 1
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.mongodb_data[0].id
  instance_id  = aws_instance.mongodb[0].id
}

# Use existing or new cluster/instance
locals {
  cluster_endpoint = var.use_existing_cluster ? var.existing_cluster_endpoint : (var.use_existing_instance ? data.aws_instance.existing_mongodb[0].private_ip : (length(aws_docdb_cluster.main) > 0 ? aws_docdb_cluster.main[0].endpoint : aws_instance.mongodb[0].private_ip))
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

variable "use_existing_cluster" {
  description = "Whether to use an existing DocumentDB cluster"
  type        = bool
  default     = false
}

variable "use_existing_instance" {
  description = "Whether to use an existing EC2 instance for MongoDB"
  type        = bool
  default     = false
}

variable "existing_security_group_id" {
  description = "Security group ID of the existing DocumentDB cluster"
  type        = string
  default     = ""
}

variable "existing_instance_security_group_id" {
  description = "Security group ID of the existing EC2 instance"
  type        = string
  default     = ""
}

variable "use_existing_subnet_group" {
  description = "Whether to use an existing subnet group"
  type        = bool
  default     = false
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

variable "existing_cluster_endpoint" {
  description = "Endpoint of the existing DocumentDB cluster"
  type        = string
  default     = ""
}

# Outputs
output "endpoint" {
  description = "Endpoint of the MongoDB cluster/instance"
  value       = local.cluster_endpoint
}

output "security_group_id" {
  description = "Security group ID of the MongoDB cluster/instance"
  value       = local.security_group_id
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
    prevent_destroy = true
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
    prevent_destroy = true
  }
} 