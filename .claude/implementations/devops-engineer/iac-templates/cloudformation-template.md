# CloudFormation Infrastructure Template

## Overview
This template provides production-ready CloudFormation patterns for deploying AWS infrastructure with best practices for nested stacks, cross-stack references, and custom resources.

## Directory Structure
```
cloudformation/
├── master-stack.yaml
├── nested-stacks/
│   ├── vpc.yaml
│   ├── security.yaml
│   ├── compute.yaml
│   ├── storage.yaml
│   └── monitoring.yaml
├── templates/
│   ├── parameters.json
│   └── tags.json
├── custom-resources/
│   └── lambda-functions/
└── scripts/
    ├── deploy.sh
    └── validate.sh
```

## Master Stack Template

### master-stack.yaml
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Master stack for application infrastructure'
Transform: AWS::Serverless-2016-10-31

# Metadata
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: "Environment Configuration"
        Parameters:
          - Environment
          - ProjectName
      - Label:
          default: "Network Configuration"
        Parameters:
          - VPCCidr
          - AvailabilityZones
      - Label:
          default: "Compute Configuration"
        Parameters:
          - InstanceType
          - MinSize
          - MaxSize
      - Label:
          default: "Database Configuration"
        Parameters:
          - DBInstanceClass
          - DBAllocatedStorage
          - DBMasterUsername

# Parameters
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - staging
      - production
    Description: Environment name
    
  ProjectName:
    Type: String
    Description: Project name for resource naming
    MinLength: 3
    MaxLength: 20
    AllowedPattern: ^[a-z][a-z0-9-]*$
    
  VPCCidr:
    Type: String
    Default: 10.0.0.0/16
    Description: CIDR block for VPC
    AllowedPattern: ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$
    
  AvailabilityZones:
    Type: List<AWS::EC2::AvailabilityZone::Name>
    Description: List of Availability Zones to use
    
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: EC2 Key Pair for SSH access
    
  TemplatesBucket:
    Type: String
    Description: S3 bucket containing nested stack templates

# Conditions
Conditions:
  IsProduction: !Equals [!Ref Environment, production]
  IsNotDevelopment: !Not [!Equals [!Ref Environment, dev]]
  CreateReadReplica: !And
    - !Condition IsProduction
    - !Equals [!Ref AWS::Region, us-east-1]

# Mappings
Mappings:
  EnvironmentConfig:
    dev:
      InstanceType: t3.micro
      MinSize: 1
      MaxSize: 3
      DBInstanceClass: db.t3.micro
      EnableMonitoring: false
    staging:
      InstanceType: t3.small
      MinSize: 2
      MaxSize: 6
      DBInstanceClass: db.t3.small
      EnableMonitoring: true
    production:
      InstanceType: t3.medium
      MinSize: 3
      MaxSize: 10
      DBInstanceClass: db.r5.large
      EnableMonitoring: true
      
  RegionMap:
    us-east-1:
      AMI: ami-0c94855ba95c71c0a
      CertificateArn: arn:aws:acm:us-east-1:123456789012:certificate/abc
    us-west-2:
      AMI: ami-0a634ae95e11c6ba9
      CertificateArn: arn:aws:acm:us-west-2:123456789012:certificate/def

# Resources
Resources:
  # Networking Stack
  NetworkStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${TemplatesBucket}.s3.amazonaws.com/nested-stacks/vpc.yaml
      Parameters:
        Environment: !Ref Environment
        ProjectName: !Ref ProjectName
        VPCCidr: !Ref VPCCidr
        AvailabilityZones: !Join
          - ','
          - !Ref AvailabilityZones
        EnableFlowLogs: !If [IsNotDevelopment, true, false]
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-network
        - Key: Component
          Value: networking
          
  # Security Stack
  SecurityStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${TemplatesBucket}.s3.amazonaws.com/nested-stacks/security.yaml
      Parameters:
        Environment: !Ref Environment
        ProjectName: !Ref ProjectName
        VPCId: !GetAtt NetworkStack.Outputs.VPCId
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-security
        - Key: Component
          Value: security
          
  # Compute Stack
  ComputeStack:
    Type: AWS::CloudFormation::Stack
    DependsOn:
      - NetworkStack
      - SecurityStack
    Properties:
      TemplateURL: !Sub https://${TemplatesBucket}.s3.amazonaws.com/nested-stacks/compute.yaml
      Parameters:
        Environment: !Ref Environment
        ProjectName: !Ref ProjectName
        VPCId: !GetAtt NetworkStack.Outputs.VPCId
        PrivateSubnetIds: !GetAtt NetworkStack.Outputs.PrivateSubnetIds
        PublicSubnetIds: !GetAtt NetworkStack.Outputs.PublicSubnetIds
        ALBSecurityGroupId: !GetAtt SecurityStack.Outputs.ALBSecurityGroupId
        AppSecurityGroupId: !GetAtt SecurityStack.Outputs.AppSecurityGroupId
        KeyPairName: !Ref KeyPairName
        InstanceType: !FindInMap [EnvironmentConfig, !Ref Environment, InstanceType]
        MinSize: !FindInMap [EnvironmentConfig, !Ref Environment, MinSize]
        MaxSize: !FindInMap [EnvironmentConfig, !Ref Environment, MaxSize]
        AMIId: !FindInMap [RegionMap, !Ref AWS::Region, AMI]
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-compute
        - Key: Component
          Value: compute
          
  # Storage Stack
  StorageStack:
    Type: AWS::CloudFormation::Stack
    DependsOn:
      - NetworkStack
      - SecurityStack
    Properties:
      TemplateURL: !Sub https://${TemplatesBucket}.s3.amazonaws.com/nested-stacks/storage.yaml
      Parameters:
        Environment: !Ref Environment
        ProjectName: !Ref ProjectName
        VPCId: !GetAtt NetworkStack.Outputs.VPCId
        DatabaseSubnetIds: !GetAtt NetworkStack.Outputs.DatabaseSubnetIds
        DBSecurityGroupId: !GetAtt SecurityStack.Outputs.DBSecurityGroupId
        DBInstanceClass: !FindInMap [EnvironmentConfig, !Ref Environment, DBInstanceClass]
        CreateReadReplica: !If [CreateReadReplica, true, false]
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-storage
        - Key: Component
          Value: storage
          
  # Monitoring Stack
  MonitoringStack:
    Type: AWS::CloudFormation::Stack
    Condition: IsNotDevelopment
    DependsOn:
      - ComputeStack
      - StorageStack
    Properties:
      TemplateURL: !Sub https://${TemplatesBucket}.s3.amazonaws.com/nested-stacks/monitoring.yaml
      Parameters:
        Environment: !Ref Environment
        ProjectName: !Ref ProjectName
        ALBArn: !GetAtt ComputeStack.Outputs.ALBArn
        TargetGroupArn: !GetAtt ComputeStack.Outputs.TargetGroupArn
        AutoScalingGroupName: !GetAtt ComputeStack.Outputs.AutoScalingGroupName
        DBInstanceId: !GetAtt StorageStack.Outputs.DBInstanceId
        SNSAlertEmail: !Ref AlertEmail
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-monitoring
        - Key: Component
          Value: monitoring

# Outputs
Outputs:
  VPCId:
    Description: VPC ID
    Value: !GetAtt NetworkStack.Outputs.VPCId
    Export:
      Name: !Sub ${AWS::StackName}-VPCId
      
  ALBEndpoint:
    Description: Application Load Balancer DNS
    Value: !GetAtt ComputeStack.Outputs.ALBDNSName
    Export:
      Name: !Sub ${AWS::StackName}-ALBEndpoint
      
  DBEndpoint:
    Description: Database endpoint
    Value: !GetAtt StorageStack.Outputs.DBEndpoint
    Export:
      Name: !Sub ${AWS::StackName}-DBEndpoint
      
  S3BucketName:
    Description: Application S3 bucket
    Value: !GetAtt StorageStack.Outputs.S3BucketName
    Export:
      Name: !Sub ${AWS::StackName}-S3Bucket
```

## Nested Stack Templates

### VPC Stack (nested-stacks/vpc.yaml)
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'VPC and networking resources'

Parameters:
  Environment:
    Type: String
  ProjectName:
    Type: String
  VPCCidr:
    Type: String
  AvailabilityZones:
    Type: CommaDelimitedList
  EnableFlowLogs:
    Type: String
    Default: false
    AllowedValues: [true, false]

Conditions:
  CreateFlowLogs: !Equals [!Ref EnableFlowLogs, true]

Resources:
  # VPC
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VPCCidr
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-vpc

  # Internet Gateway
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-igw

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref InternetGateway

  # Public Subnets
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [0, !Cidr [!Ref VPCCidr, 12, 8]]
      AvailabilityZone: !Select [0, !Ref AvailabilityZones]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-public-1
        - Key: kubernetes.io/role/elb
          Value: 1

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [1, !Cidr [!Ref VPCCidr, 12, 8]]
      AvailabilityZone: !Select [1, !Ref AvailabilityZones]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-public-2
        - Key: kubernetes.io/role/elb
          Value: 1

  PublicSubnet3:
    Type: AWS::EC2::Subnet
    Condition: CreateThirdAZ
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [2, !Cidr [!Ref VPCCidr, 12, 8]]
      AvailabilityZone: !Select [2, !Ref AvailabilityZones]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-public-3
        - Key: kubernetes.io/role/elb
          Value: 1

  # Private Subnets
  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [3, !Cidr [!Ref VPCCidr, 12, 8]]
      AvailabilityZone: !Select [0, !Ref AvailabilityZones]
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-private-1
        - Key: kubernetes.io/role/internal-elb
          Value: 1

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [4, !Cidr [!Ref VPCCidr, 12, 8]]
      AvailabilityZone: !Select [1, !Ref AvailabilityZones]
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-private-2
        - Key: kubernetes.io/role/internal-elb
          Value: 1

  # Database Subnets
  DatabaseSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [6, !Cidr [!Ref VPCCidr, 12, 8]]
      AvailabilityZone: !Select [0, !Ref AvailabilityZones]
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-db-1

  DatabaseSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [7, !Cidr [!Ref VPCCidr, 12, 8]]
      AvailabilityZone: !Select [1, !Ref AvailabilityZones]
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-db-2

  # NAT Gateways
  NATGateway1EIP:
    Type: AWS::EC2::EIP
    DependsOn: AttachGateway
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-nat-eip-1

  NATGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NATGateway1EIP.AllocationId
      SubnetId: !Ref PublicSubnet1
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-nat-1

  # Route Tables
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-public-rt

  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnetRouteTableAssociation1:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet1
      RouteTableId: !Ref PublicRouteTable

  PublicSubnetRouteTableAssociation2:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet2
      RouteTableId: !Ref PublicRouteTable

  PrivateRouteTable1:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-private-rt-1

  PrivateRoute1:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NATGateway1

  PrivateSubnetRouteTableAssociation1:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PrivateSubnet1
      RouteTableId: !Ref PrivateRouteTable1

  # VPC Flow Logs
  FlowLogRole:
    Type: AWS::IAM::Role
    Condition: CreateFlowLogs
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: vpc-flow-logs.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: CloudWatchLogPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                  - logs:DescribeLogGroups
                  - logs:DescribeLogStreams
                Resource: '*'

  FlowLogGroup:
    Type: AWS::Logs::LogGroup
    Condition: CreateFlowLogs
    Properties:
      LogGroupName: !Sub /aws/vpc/${ProjectName}-${Environment}
      RetentionInDays: 30

  FlowLog:
    Type: AWS::EC2::FlowLog
    Condition: CreateFlowLogs
    Properties:
      ResourceType: VPC
      ResourceId: !Ref VPC
      TrafficType: ALL
      LogDestinationType: cloud-watch-logs
      LogGroupName: !Ref FlowLogGroup
      DeliverLogsPermissionArn: !GetAtt FlowLogRole.Arn
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-flow-logs

# Outputs
Outputs:
  VPCId:
    Description: VPC ID
    Value: !Ref VPC
  VPCCidr:
    Description: VPC CIDR
    Value: !Ref VPCCidr
  PublicSubnetIds:
    Description: Public subnet IDs
    Value: !Join
      - ','
      - - !Ref PublicSubnet1
        - !Ref PublicSubnet2
  PrivateSubnetIds:
    Description: Private subnet IDs
    Value: !Join
      - ','
      - - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
  DatabaseSubnetIds:
    Description: Database subnet IDs
    Value: !Join
      - ','
      - - !Ref DatabaseSubnet1
        - !Ref DatabaseSubnet2
```

### Compute Stack (nested-stacks/compute.yaml)
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Compute resources including ALB, Auto Scaling, and EC2'

Parameters:
  Environment:
    Type: String
  ProjectName:
    Type: String
  VPCId:
    Type: AWS::EC2::VPC::Id
  PrivateSubnetIds:
    Type: List<AWS::EC2::Subnet::Id>
  PublicSubnetIds:
    Type: List<AWS::EC2::Subnet::Id>
  ALBSecurityGroupId:
    Type: String
  AppSecurityGroupId:
    Type: String
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
  InstanceType:
    Type: String
  MinSize:
    Type: Number
  MaxSize:
    Type: Number
  AMIId:
    Type: AWS::EC2::Image::Id

Resources:
  # Application Load Balancer
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub ${ProjectName}-${Environment}-alb
      Type: application
      Scheme: internet-facing
      SecurityGroups:
        - !Ref ALBSecurityGroupId
      Subnets: !Ref PublicSubnetIds
      EnableDeletionProtection: false
      EnableHttp2: true
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-alb

  # Target Group
  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Sub ${ProjectName}-${Environment}-tg
      Port: 80
      Protocol: HTTP
      VpcId: !Ref VPCId
      HealthCheckEnabled: true
      HealthCheckPath: /health
      HealthCheckProtocol: HTTP
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 3
      TargetType: instance
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-tg

  # ALB Listener
  ALBListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup

  # Launch Template
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateName: !Sub ${ProjectName}-${Environment}-lt
      LaunchTemplateData:
        ImageId: !Ref AMIId
        InstanceType: !Ref InstanceType
        KeyName: !Ref KeyPairName
        SecurityGroupIds:
          - !Ref AppSecurityGroupId
        IamInstanceProfile:
          Arn: !GetAtt InstanceProfile.Arn
        BlockDeviceMappings:
          - DeviceName: /dev/xvda
            Ebs:
              VolumeSize: 20
              VolumeType: gp3
              DeleteOnTermination: true
              Encrypted: true
        MetadataOptions:
          HttpEndpoint: enabled
          HttpTokens: required
          HttpPutResponseHopLimit: 1
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            yum update -y
            yum install -y amazon-cloudwatch-agent
            
            # Install application
            aws s3 cp s3://my-deployment-bucket/app.tar.gz /opt/
            tar -xzf /opt/app.tar.gz -C /opt/
            
            # Start application
            systemctl start myapp
            systemctl enable myapp
            
            # Configure CloudWatch agent
            /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
              -a fetch-config \
              -m ec2 \
              -s \
              -c ssm:${CloudWatchConfigParameter}

  # Auto Scaling Group
  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: !Sub ${ProjectName}-${Environment}-asg
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      MinSize: !Ref MinSize
      MaxSize: !Ref MaxSize
      DesiredCapacity: !Ref MinSize
      VPCZoneIdentifier: !Ref PrivateSubnetIds
      TargetGroupARNs:
        - !Ref TargetGroup
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300
      Tags:
        - Key: Name
          Value: !Sub ${ProjectName}-${Environment}-instance
          PropagateAtLaunch: true
        - Key: Environment
          Value: !Ref Environment
          PropagateAtLaunch: true

  # Scaling Policies
  ScaleUpPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AutoScalingGroupName: !Ref AutoScalingGroup
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 70

  ScaleDownPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AutoScalingGroupName: !Ref AutoScalingGroup
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 30

  # IAM Role for EC2 Instances
  InstanceRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub ${ProjectName}-${Environment}-instance-role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
      Policies:
        - PolicyName: ApplicationPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:ListBucket
                Resource:
                  - !Sub arn:aws:s3:::my-deployment-bucket/*
                  - !Sub arn:aws:s3:::my-deployment-bucket
              - Effect: Allow
                Action:
                  - secretsmanager:GetSecretValue
                Resource:
                  - !Sub arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:${ProjectName}/*

  InstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      InstanceProfileName: !Sub ${ProjectName}-${Environment}-instance-profile
      Roles:
        - !Ref InstanceRole

Outputs:
  ALBArn:
    Description: ALB ARN
    Value: !Ref ApplicationLoadBalancer
  ALBDNSName:
    Description: ALB DNS Name
    Value: !GetAtt ApplicationLoadBalancer.DNSName
  TargetGroupArn:
    Description: Target Group ARN
    Value: !Ref TargetGroup
  AutoScalingGroupName:
    Description: Auto Scaling Group Name
    Value: !Ref AutoScalingGroup
```

### Custom Resources

#### Lambda-backed Custom Resource
```yaml
# Custom resource for automatic AMI lookup
AMILookupFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: !Sub ${ProjectName}-${Environment}-ami-lookup
    Runtime: python3.9
    Handler: index.handler
    Role: !GetAtt AMILookupRole.Arn
    Code:
      ZipFile: |
        import boto3
        import json
        import cfnresponse
        
        def handler(event, context):
            try:
                if event['RequestType'] == 'Delete':
                    cfnresponse.send(event, context, cfnresponse.SUCCESS, {})
                    return
                
                ec2 = boto3.client('ec2')
                
                # Get latest Amazon Linux 2 AMI
                response = ec2.describe_images(
                    Owners=['amazon'],
                    Filters=[
                        {
                            'Name': 'name',
                            'Values': ['amzn2-ami-hvm-*-x86_64-gp2']
                        },
                        {
                            'Name': 'state',
                            'Values': ['available']
                        }
                    ],
                    IncludeDeprecated=False
                )
                
                # Sort by creation date
                images = sorted(response['Images'], 
                               key=lambda x: x['CreationDate'], 
                               reverse=True)
                
                if images:
                    ami_id = images[0]['ImageId']
                    responseData = {'AMIId': ami_id}
                    cfnresponse.send(event, context, cfnresponse.SUCCESS, responseData)
                else:
                    cfnresponse.send(event, context, cfnresponse.FAILED, 
                                   {'Error': 'No AMI found'})
                    
            except Exception as e:
                print(f"Error: {str(e)}")
                cfnresponse.send(event, context, cfnresponse.FAILED, 
                               {'Error': str(e)})

AMILookupRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Principal:
            Service: lambda.amazonaws.com
          Action: sts:AssumeRole
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    Policies:
      - PolicyName: EC2DescribeImages
        PolicyDocument:
          Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action:
                - ec2:DescribeImages
              Resource: '*'

# Custom Resource
LatestAMI:
  Type: Custom::AMILookup
  Properties:
    ServiceToken: !GetAtt AMILookupFunction.Arn
    Region: !Ref AWS::Region
```

### Deployment Script

#### scripts/deploy.sh
```bash
#!/bin/bash
set -e

# Configuration
STACK_NAME=${1:-"my-app"}
ENVIRONMENT=${2:-"dev"}
REGION=${3:-"us-east-1"}
TEMPLATE_BUCKET=${4:-"my-cfn-templates"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Deploying CloudFormation stack: $STACK_NAME-$ENVIRONMENT${NC}"

# Validate templates
echo -e "${YELLOW}Validating templates...${NC}"
for template in master-stack.yaml nested-stacks/*.yaml; do
    aws cloudformation validate-template \
        --template-body file://$template \
        --region $REGION
done

# Upload templates to S3
echo -e "${YELLOW}Uploading templates to S3...${NC}"
aws s3 sync . s3://$TEMPLATE_BUCKET/ \
    --exclude "*" \
    --include "*.yaml" \
    --region $REGION

# Package the template (for SAM transforms)
echo -e "${YELLOW}Packaging template...${NC}"
aws cloudformation package \
    --template-file master-stack.yaml \
    --s3-bucket $TEMPLATE_BUCKET \
    --output-template-file packaged-template.yaml \
    --region $REGION

# Deploy the stack
echo -e "${YELLOW}Deploying stack...${NC}"
aws cloudformation deploy \
    --template-file packaged-template.yaml \
    --stack-name $STACK_NAME-$ENVIRONMENT \
    --parameter-overrides \
        Environment=$ENVIRONMENT \
        ProjectName=$STACK_NAME \
        TemplatesBucket=$TEMPLATE_BUCKET \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region $REGION \
    --tags \
        Environment=$ENVIRONMENT \
        Project=$STACK_NAME \
        ManagedBy=CloudFormation

# Get stack outputs
echo -e "${GREEN}Stack deployed successfully!${NC}"
echo -e "${YELLOW}Stack outputs:${NC}"
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME-$ENVIRONMENT \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table \
    --region $REGION
```

## Best Practices

### 1. Template Organization
- Use nested stacks for modularity
- Keep templates under 1MB (S3 limit)
- Use consistent naming conventions
- Version control all templates

### 2. Parameter Management
- Use parameter groups for organization
- Provide sensible defaults
- Use AllowedValues for validation
- Document parameter purposes

### 3. Security
- Never hardcode credentials
- Use IAM roles and instance profiles
- Enable encryption everywhere
- Follow least privilege principle

### 4. Cross-Stack References
- Use exports sparingly (limit: 1000)
- Prefer parameter passing
- Document dependencies clearly
- Avoid circular dependencies

### 5. Custom Resources
- Always implement proper error handling
- Send response in all code paths
- Set reasonable timeouts
- Log for debugging

### 6. Change Sets
- Always preview changes before applying
- Review resource replacements carefully
- Use stack policies for protection
- Test in non-production first

### 7. Monitoring & Rollback
- Enable termination protection for production
- Set up CloudWatch alarms
- Configure stack event notifications
- Have rollback procedures ready