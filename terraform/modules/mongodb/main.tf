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
  name        = "${var.project}-${var.environment}-mongodb-sg"
  description = "Security group for MongoDB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[0]

  vpc_security_group_ids = concat(
    [aws_security_group.mongodb.id],
    var.security_group_ids
  )

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              docker run -d \
                --name mongodb \
                -p 27017:27017 \
                -v /data/db:/data/db \
                mongo:latest
              EOF

  iam_instance_profile = aws_iam_instance_profile.mongodb.name

  tags = merge(
    {
      Name = "${var.project}-${var.environment}-mongodb"
    },
    var.tags
  )
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
  cluster_endpoint = var.use_existing_cluster ? var.existing_cluster_endpoint : (var.use_existing_instance ? data.aws_instance.existing_mongodb[0].private_ip : aws_docdb_cluster.main.endpoint)
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