# Cloud Provisioning Workflow

## Overview
This workflow automates the provisioning of cloud infrastructure across multiple providers (AWS, Azure, GCP). It covers everything from initial account setup to complex multi-region deployments with proper security, networking, and compliance configurations.

## Prerequisites
- Cloud provider accounts (AWS, Azure, GCP)
- Terraform/OpenTofu installed
- Cloud CLI tools (aws-cli, az-cli, gcloud)
- Proper IAM permissions
- State storage backend configured

## Workflow Phases

### Phase 1: Foundation Setup

#### 1.1 Account Organization
```hcl
# AWS Organizations Setup
resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY",
  ]
}

resource "aws_organizations_organizational_unit" "environments" {
  for_each = toset(["production", "staging", "development"])
  
  name      = each.key
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "accounts" {
  for_each = {
    prod    = "production"
    staging = "staging"
    dev     = "development"
  }
  
  name      = "${each.key}-account"
  email     = "aws+${each.key}@company.com"
  parent_id = aws_organizations_organizational_unit.environments[each.value].id
}
```

#### 1.2 Landing Zone Configuration
```yaml
landing_zone:
  core_accounts:
    - name: "logging"
      purpose: "centralized_logging"
      services:
        - cloudtrail
        - cloudwatch
        - elasticsearch
    - name: "security"
      purpose: "security_hub"
      services:
        - guardduty
        - security_hub
        - config
    - name: "networking"
      purpose: "network_hub"
      services:
        - transit_gateway
        - direct_connect
        - route53
  
  guardrails:
    - prevent_root_usage
    - require_mfa
    - enforce_encryption
    - block_public_s3
    - require_tagging
```

### Phase 2: Network Architecture

#### 2.1 Hub-Spoke Network Design
```hcl
# Transit Gateway for AWS
module "transit_gateway" {
  source = "./modules/transit-gateway"
  
  name = "main-tgw"
  asn  = 64512
  
  enable_dns_support   = true
  enable_multicast     = false
  enable_vpn_ecmp      = true
  
  route_tables = {
    prod = {
      routes = [
        {
          destination_cidr = "10.0.0.0/8"
          attachment_id    = module.prod_vpc.tgw_attachment_id
        }
      ]
    }
    shared = {
      routes = [
        {
          destination_cidr = "172.16.0.0/12"
          attachment_id    = module.shared_vpc.tgw_attachment_id
        }
      ]
    }
  }
  
  tags = local.common_tags
}

# Multi-Region VPC Setup
module "regional_vpc" {
  for_each = var.regions
  source   = "./modules/vpc"
  
  providers = {
    aws = aws[each.key]
  }
  
  vpc_cidr = each.value.cidr
  name     = "${var.project}-${each.key}"
  
  availability_zones = data.aws_availability_zones.available[each.key].names
  
  private_subnets = [
    for i in range(3) : 
    cidrsubnet(each.value.cidr, 4, i)
  ]
  
  public_subnets = [
    for i in range(3) : 
    cidrsubnet(each.value.cidr, 4, i + 8)
  ]
  
  enable_nat_gateway = true
  single_nat_gateway = each.key == "dr" ? true : false
  
  enable_vpn_gateway = true
  enable_flow_logs   = true
  
  tags = merge(local.common_tags, {
    Region = each.key
  })
}
```

#### 2.2 Security Groups and NACLs
```hcl
# Security Group Factory
locals {
  security_group_rules = {
    web = {
      ingress = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from anywhere"
        },
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP from anywhere"
        }
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    }
    app = {
      ingress = [
        {
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = [module.alb_sg.id]
          description     = "App port from ALB"
        }
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.0.0.0/8"]
          description = "Internal traffic only"
        }
      ]
    }
    database = {
      ingress = [
        {
          from_port       = 5432
          to_port         = 5432
          protocol        = "tcp"
          security_groups = [module.app_sg.id]
          description     = "PostgreSQL from app layer"
        }
      ]
      egress = []  # No outbound for databases
    }
  }
}

module "security_groups" {
  for_each = local.security_group_rules
  source   = "./modules/security-group"
  
  name        = "${var.project}-${each.key}"
  vpc_id      = module.vpc.vpc_id
  rules       = each.value
  tags        = local.common_tags
}
```

### Phase 3: Compute Resources

#### 3.1 Container Orchestration
```hcl
# EKS Cluster Setup
module "eks" {
  source = "./modules/eks-cluster"
  
  cluster_name    = "${var.project}-${var.environment}"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  # Managed Node Groups
  eks_managed_node_groups = {
    general = {
      desired_size = 3
      min_size     = 1
      max_size     = 10
      
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      
      k8s_labels = {
        Environment = var.environment
        NodeGroup   = "general"
      }
      
      update_config = {
        max_unavailable_percentage = 50
      }
    }
    
    spot = {
      desired_size = 2
      min_size     = 0
      max_size     = 20
      
      instance_types = ["t3.large", "t3a.large", "t3.xlarge", "t3a.xlarge"]
      capacity_type  = "SPOT"
      
      k8s_labels = {
        Environment = var.environment
        NodeGroup   = "spot"
      }
      
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
  
  # OIDC Provider for IRSA
  enable_irsa = true
  
  # Cluster Add-ons
  cluster_addons = {
    coredns = {
      addon_version = "v1.10.1-eksbuild.2"
    }
    kube-proxy = {
      addon_version = "v1.28.1-eksbuild.1"
    }
    vpc-cni = {
      addon_version = "v1.14.1-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      addon_version = "v1.23.0-eksbuild.1"
    }
  }
  
  # Cluster Security
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }
  
  tags = local.common_tags
}
```

#### 3.2 Serverless Infrastructure
```hcl
# Lambda Functions with VPC
module "lambda_functions" {
  for_each = var.lambda_configs
  source   = "./modules/lambda"
  
  function_name = each.key
  runtime       = each.value.runtime
  handler       = each.value.handler
  
  source_path = each.value.source_path
  
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.security_groups["lambda"].id]
  
  environment_variables = merge(
    each.value.environment_variables,
    {
      ENVIRONMENT = var.environment
      REGION      = data.aws_region.current.name
    }
  )
  
  # IAM
  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      resources = [
        aws_dynamodb_table.main.arn,
        "${aws_dynamodb_table.main.arn}/*"
      ]
    }
    secrets = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = [
        "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/*"
      ]
    }
  }
  
  # Tracing
  tracing_config = {
    mode = "Active"
  }
  
  # Concurrency
  reserved_concurrent_executions = each.value.reserved_concurrency
  
  tags = local.common_tags
}
```

### Phase 4: Data Layer

#### 4.1 Database Infrastructure
```hcl
# RDS Multi-AZ Setup
module "rds" {
  source = "./modules/rds"
  
  identifier = "${var.project}-${var.environment}-db"
  
  engine               = "postgres"
  engine_version       = "15.4"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = var.environment == "production" ? "db.r6g.xlarge" : "db.t3.medium"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_encrypted     = true
  storage_type          = "gp3"
  
  database_name = var.project_name
  username      = "dbadmin"
  port          = 5432
  
  multi_az               = var.environment == "production" ? true : false
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_groups["database"].id]
  
  # Backups
  backup_retention_period = var.environment == "production" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group     = true
  
  # Parameter group
  parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "log_statement"
      value = "all"
    }
  ]
  
  tags = local.common_tags
}

# DynamoDB Global Tables
resource "aws_dynamodb_table" "global" {
  name         = "${var.project}-${var.environment}-global"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "sort_key"
  
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  attribute {
    name = "sort_key"
    type = "S"
  }
  
  global_secondary_index {
    name            = "gsi1"
    hash_key        = "gsi1pk"
    range_key       = "gsi1sk"
    projection_type = "ALL"
  }
  
  replica {
    region_name = "us-west-2"
  }
  
  replica {
    region_name = "eu-west-1"
  }
  
  server_side_encryption {
    enabled = true
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = local.common_tags
}
```

#### 4.2 Storage Solutions
```hcl
# S3 Buckets with Lifecycle and Replication
module "s3_buckets" {
  for_each = var.s3_buckets
  source   = "./modules/s3"
  
  bucket_name = "${var.project}-${var.environment}-${each.key}"
  
  # Versioning
  versioning = {
    enabled = true
  }
  
  # Encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  # Lifecycle Rules
  lifecycle_rule = [
    {
      id      = "transition-old-versions"
      enabled = true
      
      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]
  
  # Replication
  replication_configuration = var.environment == "production" ? {
    role = aws_iam_role.replication.arn
    
    rules = [
      {
        id     = "replicate-to-dr"
        status = "Enabled"
        
        destination = {
          bucket        = module.s3_buckets_dr[each.key].s3_bucket_arn
          storage_class = "STANDARD_IA"
        }
      }
    ]
  } : null
  
  # Bucket Policies
  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceSSLRequestsOnly"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.project}-${var.environment}-${each.key}/*",
          "arn:aws:s3:::${var.project}-${var.environment}-${each.key}"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
  
  tags = local.common_tags
}
```

### Phase 5: Security & Compliance

#### 5.1 IAM and Access Control
```hcl
# RBAC Implementation
locals {
  role_definitions = {
    developer = {
      managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      inline_policies = {
        developer_access = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "eks:DescribeCluster",
                "eks:ListClusters",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
              ]
              Resource = "*"
            }
          ]
        })
      }
    }
    
    admin = {
      managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      inline_policies = {}
    }
    
    ci_cd = {
      managed_policies = []
      inline_policies = {
        deployment_access = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "ecr:*",
                "ecs:*",
                "eks:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudformation:*",
                "s3:*"
              ]
              Resource = "*"
              Condition = {
                StringEquals = {
                  "aws:RequestedRegion": var.allowed_regions
                }
              }
            }
          ]
        })
      }
    }
  }
}

# Create IAM Roles
module "iam_roles" {
  for_each = local.role_definitions
  source   = "./modules/iam-role"
  
  role_name = "${var.project}-${each.key}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })
  
  managed_policy_arns = each.value.managed_policies
  inline_policies     = each.value.inline_policies
  
  tags = local.common_tags
}
```

#### 5.2 Compliance Automation
```hcl
# AWS Config Rules
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project}-recorder"
  role_arn = aws_iam_role.config.arn
  
  recording_group {
    all_supported = true
  }
}

resource "aws_config_config_rule" "compliance_rules" {
  for_each = var.compliance_rules
  
  name = each.key
  
  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }
  
  input_parameters = jsonencode(each.value.parameters)
  
  depends_on = [aws_config_configuration_recorder.main]
}

# Security Hub
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "standards" {
  for_each = toset([
    "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0",
    "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1",
    "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.2.0"
  ])
  
  standards_arn = each.value
  
  depends_on = [aws_securityhub_account.main]
}
```

### Phase 6: Monitoring & Observability

#### 6.1 CloudWatch Setup
```hcl
# Centralized Logging
module "cloudwatch_logs" {
  source = "./modules/cloudwatch-logs"
  
  log_groups = {
    application = {
      retention_days = 30
      kms_key_id     = aws_kms_key.logs.arn
    }
    infrastructure = {
      retention_days = 90
      kms_key_id     = aws_kms_key.logs.arn
    }
    security = {
      retention_days = 365
      kms_key_id     = aws_kms_key.logs.arn
    }
  }
  
  # Metric Filters
  metric_filters = {
    error_count = {
      log_group_name = "/aws/application"
      pattern        = "[ERROR]"
      metric_transformation = {
        name      = "ErrorCount"
        namespace = "Application"
        value     = "1"
      }
    }
    unauthorized_api_calls = {
      log_group_name = "/aws/cloudtrail"
      pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
      metric_transformation = {
        name      = "UnauthorizedAPICalls"
        namespace = "Security"
        value     = "1"
      }
    }
  }
  
  # Alarms
  metric_alarms = {
    high_error_rate = {
      alarm_name          = "high-error-rate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ErrorCount"
      namespace           = "Application"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "This metric monitors error rate"
      alarm_actions       = [aws_sns_topic.alerts.arn]
    }
  }
  
  tags = local.common_tags
}
```

## Cost Optimization

### Resource Tagging Strategy
```hcl
locals {
  mandatory_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
  
  common_tags = merge(
    local.mandatory_tags,
    var.additional_tags
  )
}

# Tag Policy
resource "aws_organizations_policy" "tagging" {
  name = "mandatory-tags"
  type = "TAG_POLICY"
  
  content = jsonencode({
    tags = {
      Project = {
        tag_key = "Project"
        enforced_for = ["ec2:instance", "ec2:volume", "rds:db", "s3:bucket"]
      }
      Environment = {
        tag_key = "Environment"
        enforced_for = ["ec2:instance", "ec2:volume", "rds:db", "s3:bucket"]
      }
      CostCenter = {
        tag_key = "CostCenter"
        enforced_for = ["ec2:instance", "ec2:volume", "rds:db", "s3:bucket"]
      }
    }
  })
}
```

### Automated Cost Controls
```hcl
# Budget Alerts
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }
}

# Instance Scheduler
module "instance_scheduler" {
  source = "./modules/instance-scheduler"
  
  schedules = {
    office_hours = {
      name         = "office-hours"
      description  = "Start at 8 AM, stop at 8 PM on weekdays"
      timezone     = "US/Eastern"
      begin_time   = "08:00"
      end_time     = "20:00"
      days_active  = ["mon", "tue", "wed", "thu", "fri"]
    }
    always_on = {
      name         = "always-on"
      description  = "Running 24/7"
      timezone     = "UTC"
    }
  }
  
  tagged_instances = {
    Schedule = "office-hours"  # Tag key and value to identify instances
  }
}
```

## Disaster Recovery

### Multi-Region Failover
```hcl
# Route53 Health Checks and Failover
resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_endpoint
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"
  
  tags = merge(local.common_tags, {
    Name = "primary-health-check"
  })
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www"
  type    = "A"
  
  set_identifier = "Primary"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = true
  }
  
  health_check_id = aws_route53_health_check.primary.id
}
```

## Success Metrics
- **Provisioning Time**: < 30 minutes for complete stack
- **Infrastructure Drift**: Zero drift detected
- **Cost Optimization**: 30% reduction through automation
- **Security Compliance**: 100% Config rule compliance
- **Disaster Recovery**: RTO < 15 minutes, RPO < 5 minutes