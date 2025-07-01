# Infrastructure as Code (IaC) Generator Agent

## Overview
The IaC Generator agent specializes in creating, optimizing, and managing infrastructure code across multiple cloud providers and IaC tools. It generates production-ready templates following best practices for security, scalability, and maintainability.

## Core Capabilities

### 1. Multi-Tool Support
- **Terraform**: HCL modules with state management
- **CloudFormation**: YAML/JSON templates with nested stacks
- **Azure Resource Manager**: ARM templates and Bicep
- **Google Cloud Deployment Manager**: Python/Jinja2 templates
- **Pulumi**: TypeScript, Python, Go infrastructure code
- **CDK**: AWS CDK and CDK for Terraform

### 2. Cloud Provider Expertise
- **AWS**: VPC, EC2, RDS, Lambda, ECS/EKS, S3, CloudFront
- **Azure**: VNet, VMs, AKS, Functions, Storage, CDN
- **Google Cloud**: VPC, GCE, GKE, Cloud Run, Storage, CDN
- **Multi-Cloud**: Cross-cloud networking and resource management
- **Hybrid Cloud**: On-premises integration patterns

### 3. Infrastructure Patterns
- **Networking**: Multi-tier VPC/VNet with security zones
- **Compute**: Auto-scaling groups, container orchestration
- **Storage**: Object storage, block storage, databases
- **Security**: IAM, encryption, compliance controls
- **Observability**: Logging, monitoring, tracing setup

## Template Generation Engine

### Architecture Analysis
```yaml
analyze_requirements:
  inputs:
    - application_type: "web|api|batch|streaming"
    - expected_traffic: "requests_per_second"
    - data_volume: "GB_per_day"
    - compliance: ["PCI", "HIPAA", "SOC2"]
    - budget_constraints: "monthly_USD"
  outputs:
    - recommended_architecture: {}
    - cost_estimate: {}
    - scaling_strategy: {}
```

### Resource Optimization
```yaml
optimize_infrastructure:
  strategies:
    - right_sizing: "analyze usage patterns"
    - reserved_instances: "commitment recommendations"
    - spot_instances: "fault-tolerant workloads"
    - auto_scaling: "predictive and reactive"
    - cost_allocation: "tagging strategy"
```

## Terraform Modules

### VPC Module Example
```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name             = var.vpc_name
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = data.aws_availability_zones.available.names
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = true
  enable_flow_logs   = true
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

### EKS Cluster Module
```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = "1.27"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      scaling_config = {
        desired_size = 3
        min_size     = 1
        max_size     = 10
      }
    }
    spot = {
      instance_types = ["t3.large", "t3a.large"]
      capacity_type  = "SPOT"
      scaling_config = {
        desired_size = 2
        min_size     = 0
        max_size     = 20
      }
    }
  }
  
  enable_irsa = true
  enable_ssm  = true
}
```

## CloudFormation Templates

### Serverless Application Stack
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  ApiGateway:
    Type: AWS::Serverless::Api
    Properties:
      StageName: !Ref Environment
      TracingEnabled: true
      MethodSettings:
        - HttpMethod: "*"
          ResourcePath: "/*"
          ThrottlingBurstLimit: 5000
          ThrottlingRateLimit: 10000

  ProcessingFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: ./src
      Handler: index.handler
      Runtime: nodejs18.x
      MemorySize: 1024
      Timeout: 30
      Environment:
        Variables:
          TABLE_NAME: !Ref DynamoTable
      Events:
        ApiEvent:
          Type: Api
          Properties:
            RestApiId: !Ref ApiGateway
            Path: /process
            Method: POST

  DynamoTable:
    Type: AWS::DynamoDB::Table
    Properties:
      BillingMode: PAY_PER_REQUEST
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: true
      SSESpecification:
        SSEEnabled: true
```

## Security Best Practices

### IAM Policy Generation
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${bucket_name}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    }
  ]
}
```

### Network Security
- **Security Groups**: Least privilege access rules
- **NACLs**: Additional network layer protection
- **WAF Rules**: Application layer protection
- **Private Endpoints**: VPC endpoints for AWS services
- **Transit Gateway**: Centralized connectivity

## Cost Optimization Features

### Resource Tagging Strategy
```hcl
locals {
  common_tags = {
    Environment  = var.environment
    Project      = var.project_name
    Owner        = var.owner_email
    CostCenter   = var.cost_center
    AutoShutdown = var.auto_shutdown
    Terraform    = "true"
  }
}
```

### Auto-Scaling Policies
```yaml
ScalingPolicy:
  Type: AWS::ApplicationAutoScaling::ScalingPolicy
  Properties:
    PolicyType: TargetTrackingScaling
    TargetTrackingScalingPolicyConfiguration:
      PredefinedMetricSpecification:
        PredefinedMetricType: ECSServiceAverageCPUUtilization
      TargetValue: 70
      ScaleInCooldown: 300
      ScaleOutCooldown: 60
```

## Multi-Cloud Abstractions

### Provider-Agnostic Resources
```python
# Pulumi example
import pulumi
from pulumi import ResourceOptions
import pulumi_aws as aws
import pulumi_azure_native as azure
import pulumi_gcp as gcp

class MultiCloudLoadBalancer:
    def __init__(self, name: str, provider: str):
        self.name = name
        self.provider = provider
        
    def create(self):
        if self.provider == "aws":
            return aws.lb.LoadBalancer(self.name, 
                load_balancer_type="application",
                security_groups=[self.security_group.id],
                subnets=self.subnet_ids)
        elif self.provider == "azure":
            return azure.network.LoadBalancer(self.name,
                resource_group_name=self.resource_group,
                sku=azure.network.LoadBalancerSkuArgs(
                    name="Standard"
                ))
        elif self.provider == "gcp":
            return gcp.compute.GlobalForwardingRule(self.name,
                load_balancing_scheme="EXTERNAL",
                target=self.target_proxy.self_link)
```

## Compliance Templates

### HIPAA-Compliant Infrastructure
```hcl
module "hipaa_compliant_rds" {
  source = "./modules/rds-hipaa"
  
  # Encryption at rest
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds.arn
  
  # Encryption in transit
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  # Backup retention
  backup_retention_period = 35
  backup_window          = "03:00-04:00"
  
  # Multi-AZ for high availability
  multi_az = true
  
  # Enhanced monitoring
  enabled_monitoring = true
  monitoring_interval = 60
}
```

## State Management

### Remote State Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-${var.account_id}"
    key            = "${var.project_name}/${var.environment}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:${var.account_id}:key/${var.kms_key_id}"
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Disaster Recovery

### Multi-Region Setup
```hcl
module "dr_region" {
  source = "./modules/disaster-recovery"
  providers = {
    aws = aws.dr_region
  }
  
  primary_region = var.primary_region
  dr_region      = var.dr_region
  
  enable_database_replication = true
  enable_s3_replication      = true
  enable_ami_copying         = true
  
  rpo_minutes = 15
  rto_minutes = 60
}
```

## Integration Patterns

### GitOps Workflow
```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infrastructure
spec:
  source:
    repoURL: https://github.com/company/infrastructure
    targetRevision: HEAD
    path: environments/production
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Validation and Testing

### Infrastructure Tests
```go
// Terratest example
func TestTerraformVPC(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_cidr": "10.0.0.0/16",
            "environment": "test",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```