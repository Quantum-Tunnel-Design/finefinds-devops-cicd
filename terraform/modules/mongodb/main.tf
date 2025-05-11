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
  mongodb_credentials = jsondecode(data.aws_secretsmanager_secret_version.mongodb_password.secret_string)
  mongodb_password    = local.mongodb_credentials.password
  cluster_endpoint    = var.use_existing_cluster ? var.existing_cluster_endpoint : aws_docdb_cluster.main.endpoint
}

# MongoDB Security Group
resource "aws_security_group" "mongodb" {
  name        = "${var.project}-${var.environment}-mongodb-sg"
  description = "Security group for MongoDB DocumentDB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Tighten this in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.project}-${var.environment}-mongodb-sg"
    },
    var.tags
  )
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

# MongoDB Cluster (DocumentDB)
resource "aws_docdb_cluster" "main" {
  cluster_identifier = var.name
  engine            = "docdb"
  master_username   = var.admin_username # Using variable for admin username
  master_password   = local.mongodb_password
  vpc_security_group_ids = [aws_security_group.mongodb.id]
  db_subnet_group_name   = aws_docdb_subnet_group.main.name
  skip_final_snapshot = var.skip_final_snapshot
  instance_class      = var.instance_class # Added instance_class to cluster as it's often set here too
  # Add other DocumentDB parameters as needed, e.g., backup_retention_period, preferred_maintenance_window
  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# MongoDB Instance (DocumentDB)
resource "aws_docdb_cluster_instance" "main" {
  count              = 1 # Or var.instance_count if you want to control the number of instances
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

# Use existing or new cluster/instance
locals {
  cluster_endpoint = var.use_existing_cluster ? var.existing_cluster_endpoint : (var.use_existing_instance ? data.aws_instance.existing_mongodb[0].private_ip : aws_docdb_cluster.main.endpoint)
}

# Commenting out IAM roles that seemed related to ECS, not directly to DocumentDB provisioning
# // ... existing code ... (for aws_iam_role.ecs_execution_role & ecs_task_role) ...

# IAM Role for MongoDB
resource "aws_iam_role" "mongodb" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-mongodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Instance Profile for MongoDB
resource "aws_iam_instance_profile" "mongodb" {
  name = "${var.project}-${var.environment}-mongodb-profile"
  role = aws_iam_role.mongodb[0].name
}

# IAM Policy for MongoDB
resource "aws_iam_role_policy" "mongodb" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.project}-${var.environment}-mongodb-policy"
  role  = aws_iam_role.mongodb[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data source for Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
} 