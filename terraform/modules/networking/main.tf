# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_config.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.vpc_config.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_config.public_subnets[count.index]
  availability_zone = var.vpc_config.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-public-${count.index + 1}"
      Tier = "Public"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.vpc_config.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_config.private_subnets[count.index]
  availability_zone = var.vpc_config.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-private-${count.index + 1}"
      Tier = "Private"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Database Subnets
resource "aws_subnet" "database" {
  count             = length(var.vpc_config.database_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_config.database_subnets[count.index]
  availability_zone = var.vpc_config.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-database-${count.index + 1}"
      Tier = "Database"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.vpc_config.single_nat_gateway ? 1 : length(var.vpc_config.private_subnets)
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = var.vpc_config.enable_nat_gateway ? (var.vpc_config.single_nat_gateway ? 1 : length(var.vpc_config.private_subnets)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]

  lifecycle {
    create_before_destroy = true
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-public-rt"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Private Route Tables
resource "aws_route_table" "private" {
  count  = var.vpc_config.enable_nat_gateway ? (var.vpc_config.single_nat_gateway ? 1 : length(var.vpc_config.private_subnets)) : 1
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.vpc_config.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.vpc_config.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-private-rt-${count.index + 1}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Database Route Table
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-database-rt"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.vpc_config.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count          = length(var.vpc_config.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.vpc_config.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# Database Route Table Associations
resource "aws_route_table_association" "database" {
  count          = length(var.vpc_config.database_subnets)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  count = var.vpc_config.enable_flow_log ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_log[0].arn
  log_destination = aws_cloudwatch_log_group.flow_log[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = var.tags
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_log" {
  count             = var.vpc_config.enable_flow_log ? 1 : 0
  name              = "/aws/vpc/${var.name_prefix}-flow-log"
  retention_in_days = var.vpc_config.flow_log_retention

  tags = var.tags
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_log" {
  count = var.vpc_config.enable_flow_log ? 1 : 0

  name = "${var.name_prefix}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_log" {
  count = var.vpc_config.enable_flow_log ? 1 : 0

  name = "${var.name_prefix}-flow-log-policy"
  role = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
} 