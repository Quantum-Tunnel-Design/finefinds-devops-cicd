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

locals {
  mongodb_password = jsondecode(data.aws_secretsmanager_secret_version.mongodb_password.secret_string)
}

# MongoDB Security Group
resource "aws_security_group" "mongodb" {
  name        = var.security_group_name
  description = "Security group for MongoDB instance"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 27017
    to_port     = 27017
    cidr_blocks = var.vpc_cidr_blocks
  }

  tags = {
    Name        = var.security_group_name
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

# MongoDB Subnet Group
resource "aws_docdb_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-mongodb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# MongoDB Cluster
resource "aws_docdb_cluster" "main" {
  cluster_identifier = var.name
  engine            = "docdb"
  master_username   = "admin"
  master_password   = local.mongodb_password

  vpc_security_group_ids = [aws_security_group.mongodb.id]
  db_subnet_group_name   = aws_docdb_subnet_group.main.name

  skip_final_snapshot = var.skip_final_snapshot

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# MongoDB Instance
resource "aws_docdb_cluster_instance" "main" {
  count              = 1
  identifier         = "${var.name}-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class

  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
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

  vpc_security_group_ids = [var.existing_security_group_id]

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
                  pwd: "${local.mongodb_password}",
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

# Outputs
output "endpoint" {
  description = "MongoDB endpoint"
  value       = local.cluster_endpoint
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