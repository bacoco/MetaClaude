# Terraform Infrastructure Template

## Overview
This template provides a production-ready Terraform structure for deploying cloud infrastructure with best practices for modularity, security, and maintainability.

## Directory Structure
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── production/
├── modules/
│   ├── networking/
│   ├── compute/
│   ├── storage/
│   ├── security/
│   └── monitoring/
├── global/
│   ├── iam/
│   └── dns/
└── scripts/
    ├── init-backend.sh
    └── validate.sh
```

## Core Configuration

### Backend Configuration
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-${var.account_id}"
    key            = "${var.environment}/${var.project}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:${var.account_id}:key/${var.kms_key_id}"
    dynamodb_table = "terraform-state-lock"
    
    workspace_key_prefix = "workspaces"
  }
}

# Remote state data sources
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${var.account_id}"
    key    = "${var.environment}/networking/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Provider Configuration
```hcl
# providers.tf
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Primary region provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
  
  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/TerraformExecutionRole"
    session_name = "terraform-${var.environment}"
  }
}

# Secondary region provider for DR
provider "aws" {
  alias  = "dr"
  region = var.dr_region
  
  default_tags {
    tags = merge(local.common_tags, {
      Region = var.dr_region
      Purpose = "disaster-recovery"
    })
  }
}
```

## Networking Module

### VPC Module
```hcl
# modules/networking/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = false
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${count.index + 1}"
    Type = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${count.index + 1}"
    Type = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# NAT Gateways
resource "aws_eip" "nat" {
  count = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
    Type = "public"
  })
}

resource "aws_route_table" "private" {
  count = var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)
  
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
    Type = "private"
  })
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0
  
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  
  tags = var.tags
}
```

### Security Groups Module
```hcl
# modules/networking/security-groups/main.tf
locals {
  # Common port definitions
  ports = {
    http    = 80
    https   = 443
    ssh     = 22
    rdp     = 3389
    mysql   = 3306
    postgres = 5432
    redis   = 6379
    mongo   = 27017
  }
}

# Dynamic Security Group
resource "aws_security_group" "this" {
  name_prefix = "${var.name_prefix}-"
  description = var.description
  vpc_id      = var.vpc_id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Dynamic Ingress Rules
resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, rule in var.ingress_rules : idx => rule }
  
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.this.id
  
  # Handle different source types
  cidr_blocks              = try(each.value.cidr_blocks, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
  
  description = each.value.description
}

# Dynamic Egress Rules
resource "aws_security_group_rule" "egress" {
  for_each = { for idx, rule in var.egress_rules : idx => rule }
  
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.this.id
  
  cidr_blocks              = try(each.value.cidr_blocks, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
  
  description = each.value.description
}
```

## Compute Module

### EKS Cluster
```hcl
# modules/compute/eks/main.tf
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version
  
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }
  
  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }
  
  enabled_cluster_log_types = var.cluster_log_types
  
  tags = var.tags
  
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}

# OIDC Provider for IRSA
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  
  tags = var.tags
}

# Managed Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups
  
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_subnet_ids
  
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }
  
  update_config {
    max_unavailable_percentage = try(each.value.max_unavailable_percentage, 33)
  }
  
  instance_types = each.value.instance_types
  capacity_type  = try(each.value.capacity_type, "ON_DEMAND")
  
  remote_access {
    ec2_ssh_key               = try(each.value.key_name, null)
    source_security_group_ids = try(each.value.source_security_group_ids, [])
  }
  
  launch_template {
    id      = aws_launch_template.node_group[each.key].id
    version = aws_launch_template.node_group[each.key].latest_version
  }
  
  dynamic "taint" {
    for_each = try(each.value.taints, [])
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }
  
  labels = each.value.labels
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.key}"
  })
  
  lifecycle {
    ignore_changes        = [scaling_config[0].desired_size]
    create_before_destroy = true
  }
}

# Launch Template for Node Groups
resource "aws_launch_template" "node_group" {
  for_each = var.node_groups
  
  name_prefix = "${var.cluster_name}-${each.key}-"
  
  block_device_mappings {
    device_name = "/dev/xvda"
    
    ebs {
      volume_size           = try(each.value.disk_size, 100)
      volume_type           = try(each.value.disk_type, "gp3")
      iops                  = try(each.value.disk_iops, null)
      throughput            = try(each.value.disk_throughput, null)
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }
  
  monitoring {
    enabled = true
  }
  
  tag_specifications {
    resource_type = "instance"
    
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-${each.key}-node"
    })
  }
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name        = aws_eks_cluster.main.name
    cluster_endpoint    = aws_eks_cluster.main.endpoint
    cluster_ca          = aws_eks_cluster.main.certificate_authority[0].data
    bootstrap_arguments = try(each.value.bootstrap_arguments, "")
  }))
}
```

### Lambda Functions
```hcl
# modules/compute/lambda/main.tf
resource "aws_lambda_function" "this" {
  filename         = var.filename
  source_code_hash = var.source_code_hash
  function_name    = var.function_name
  role            = aws_iam_role.lambda.arn
  handler         = var.handler
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  
  environment {
    variables = var.environment_variables
  }
  
  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }
  
  dead_letter_config {
    target_arn = var.dead_letter_target_arn
  }
  
  tracing_config {
    mode = var.tracing_mode
  }
  
  layers = var.layers
  
  reserved_concurrent_executions = var.reserved_concurrent_executions
  
  tags = var.tags
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  
  tags = var.tags
}

# Lambda Permissions
resource "aws_lambda_permission" "this" {
  for_each = var.allowed_triggers
  
  statement_id  = each.key
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = each.value.principal
  source_arn    = each.value.source_arn
}

# Auto Scaling
resource "aws_appautoscaling_target" "lambda" {
  count = var.enable_auto_scaling ? 1 : 0
  
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "function:${aws_lambda_function.this.function_name}:provisioned"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"
  service_namespace  = "lambda"
}

resource "aws_appautoscaling_policy" "lambda" {
  count = var.enable_auto_scaling ? 1 : 0
  
  name               = "${var.function_name}-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.lambda[0].resource_id
  scalable_dimension = aws_appautoscaling_target.lambda[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.lambda[0].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "LambdaProvisionedConcurrencyUtilization"
    }
    target_value = var.target_utilization
  }
}
```

## Storage Module

### RDS Database
```hcl
# modules/storage/rds/main.tf
resource "aws_db_instance" "main" {
  identifier = var.identifier
  
  # Engine
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  
  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id           = var.kms_key_id
  
  # Database
  db_name  = var.database_name
  username = var.username
  password = var.password
  port     = var.port
  
  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false
  
  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # High Availability
  multi_az = var.multi_az
  
  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_id : null
  monitoring_interval            = var.monitoring_interval
  monitoring_role_arn           = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  
  # Parameters
  parameter_group_name = aws_db_parameter_group.main.name
  
  tags = var.tags
  
  lifecycle {
    ignore_changes = [password]
  }
}

# Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  
  tags = merge(var.tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

# Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.identifier}-params"
  family = var.family
  
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.identifier}-params"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Read Replicas
resource "aws_db_instance" "read_replica" {
  count = var.read_replica_count
  
  identifier             = "${var.identifier}-read-${count.index + 1}"
  replicate_source_db    = aws_db_instance.main.identifier
  instance_class         = var.read_replica_instance_class
  publicly_accessible    = false
  auto_minor_version_upgrade = false
  
  # Different AZ for each replica
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  
  tags = merge(var.tags, {
    Name = "${var.identifier}-read-${count.index + 1}"
    Type = "read-replica"
  })
}
```

### S3 Buckets
```hcl
# modules/storage/s3/main.tf
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  
  tags = var.tags
}

# Bucket Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_algorithm
      kms_master_key_id = var.encryption_algorithm == "aws:kms" ? var.kms_key_id : null
    }
  }
}

# Bucket Policy
resource "aws_s3_bucket_policy" "this" {
  count = var.attach_policy ? 1 : 0
  
  bucket = aws_s3_bucket.this.id
  policy = var.policy
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id
  
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0
  
  bucket = aws_s3_bucket.this.id
  
  dynamic "rule" {
    for_each = var.lifecycle_rules
    
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"
      
      dynamic "transition" {
        for_each = try(rule.value.transitions, [])
        
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
      
      dynamic "noncurrent_version_transition" {
        for_each = try(rule.value.noncurrent_version_transitions, [])
        
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
      
      dynamic "expiration" {
        for_each = try(rule.value.expiration, null) != null ? [rule.value.expiration] : []
        
        content {
          days = expiration.value.days
        }
      }
      
      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration, null) != null ? [rule.value.noncurrent_version_expiration] : []
        
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }
    }
  }
}

# CORS Configuration
resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0
  
  bucket = aws_s3_bucket.this.id
  
  dynamic "cors_rule" {
    for_each = var.cors_rules
    
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# Replication Configuration
resource "aws_s3_bucket_replication_configuration" "this" {
  count = var.replication_configuration != null ? 1 : 0
  
  role   = var.replication_configuration.role
  bucket = aws_s3_bucket.this.id
  
  dynamic "rule" {
    for_each = var.replication_configuration.rules
    
    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = try(rule.value.priority, null)
      
      destination {
        bucket        = rule.value.destination_bucket
        storage_class = try(rule.value.storage_class, "STANDARD")
        
        dynamic "replication_time" {
          for_each = try(rule.value.replication_time, null) != null ? [rule.value.replication_time] : []
          
          content {
            status = replication_time.value.status
            time {
              minutes = replication_time.value.minutes
            }
          }
        }
      }
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.this]
}
```

## Monitoring Module

### CloudWatch Alarms
```hcl
# modules/monitoring/cloudwatch/main.tf
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = var.alarms
  
  alarm_name          = each.key
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.description
  treat_missing_data  = each.value.treat_missing_data
  
  dimensions = each.value.dimensions
  
  alarm_actions             = concat(var.sns_topic_arns, try(each.value.alarm_actions, []))
  ok_actions                = concat(var.sns_topic_arns, try(each.value.ok_actions, []))
  insufficient_data_actions = try(each.value.insufficient_data_actions, [])
  
  tags = var.tags
}

# Composite Alarms
resource "aws_cloudwatch_composite_alarm" "this" {
  for_each = var.composite_alarms
  
  alarm_name          = each.key
  alarm_description   = each.value.description
  alarm_rule          = each.value.alarm_rule
  actions_enabled     = each.value.actions_enabled
  
  alarm_actions             = concat(var.sns_topic_arns, try(each.value.alarm_actions, []))
  ok_actions                = concat(var.sns_topic_arns, try(each.value.ok_actions, []))
  insufficient_data_actions = try(each.value.insufficient_data_actions, [])
  
  tags = var.tags
}

# Dashboard
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.dashboard_name
  
  dashboard_body = jsonencode({
    widgets = [
      for widget in var.widgets : {
        type   = widget.type
        width  = widget.width
        height = widget.height
        x      = widget.x
        y      = widget.y
        
        properties = merge(
          {
            metrics = widget.metrics
            period  = widget.period
            stat    = widget.stat
            region  = widget.region
            title   = widget.title
          },
          widget.additional_properties
        )
      }
    ]
  })
}
```

## Common Variables

### variables.tf
```hcl
# Common variables used across modules
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Locals for common tags
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  )
}
```

## Validation Script

### scripts/validate.sh
```bash
#!/bin/bash
set -e

echo "🔍 Running Terraform validation..."

# Initialize terraform
terraform init -backend=false

# Format check
echo "Checking formatting..."
terraform fmt -check -recursive

# Validate configuration
echo "Validating configuration..."
terraform validate

# Security scanning with tfsec
echo "Running security scan..."
if command -v tfsec &> /dev/null; then
    tfsec . --minimum-severity HIGH
else
    echo "⚠️  tfsec not installed, skipping security scan"
fi

# Cost estimation with infracost
echo "Estimating costs..."
if command -v infracost &> /dev/null; then
    infracost breakdown --path .
else
    echo "⚠️  infracost not installed, skipping cost estimation"
fi

echo "✅ Validation complete!"
```

## Best Practices

1. **State Management**
   - Use remote state with locking
   - Separate state files by environment
   - Enable versioning on state bucket

2. **Security**
   - Never hardcode secrets
   - Use AWS Secrets Manager or Parameter Store
   - Enable encryption everywhere
   - Follow least privilege principle

3. **Tagging Strategy**
   - Consistent tagging across all resources
   - Include cost allocation tags
   - Add automation tags

4. **Module Design**
   - Keep modules small and focused
   - Use semantic versioning
   - Document all variables and outputs
   - Include examples for each module