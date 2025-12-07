terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.30"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure AWS Provider for account-level operations
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Databricks provider for account-level operations (workspace creation, UC metastore)
provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  # Authentication via environment variables:
  # DATABRICKS_USERNAME and DATABRICKS_PASSWORD
  # OR DATABRICKS_TOKEN (account-level token)
}

# Databricks provider for workspace-level operations (after workspace is created)
provider "databricks" {
  alias = "workspace"
  host  = databricks_mws_workspaces.this.workspace_url
  # Authentication via environment variables
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get available AWS availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC for Databricks workspace
resource "aws_vpc" "databricks_vpc" {
  count = var.use_existing_vpc ? 0 : 1

  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-vpc"
    }
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "databricks_igw" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.databricks_vpc[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-igw"
    }
  )
}

# Create private subnets
resource "aws_subnet" "private" {
  count = var.use_existing_vpc ? 0 : length(var.private_subnet_cidr_blocks)

  vpc_id            = aws_vpc.databricks_vpc[0].id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-private-subnet-${count.index + 1}"
    }
  )
}

# Create NAT Gateway EIP
resource "aws_eip" "nat" {
  count  = var.use_existing_vpc ? 0 : 1
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-nat-eip"
    }
  )
}

# Create NAT Gateway
resource "aws_nat_gateway" "databricks_nat" {
  count         = var.use_existing_vpc ? 0 : 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.private[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-nat-gateway"
    }
  )

  depends_on = [aws_internet_gateway.databricks_igw]
}

# Create route table for private subnets
resource "aws_route_table" "private" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.databricks_vpc[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.databricks_nat[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-private-rt"
    }
  )
}

# Associate private subnets with route table
resource "aws_route_table_association" "private" {
  count          = var.use_existing_vpc ? 0 : length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# Security group for Databricks workspace
resource "aws_security_group" "databricks_sg" {
  count       = var.use_existing_vpc ? 0 : 1
  name        = "${var.workspace_prefix}-sg"
  description = "Security group for Databricks workspace"
  vpc_id      = aws_vpc.databricks_vpc[0].id

  # Allow all egress traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-sg"
    }
  )
}

# Allow all traffic within the security group (required for Databricks)
resource "aws_security_group_rule" "self" {
  count                    = var.use_existing_vpc ? 0 : 1
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.databricks_sg[0].id
  source_security_group_id = aws_security_group.databricks_sg[0].id
}

# Create S3 bucket for Databricks root storage
resource "aws_s3_bucket" "root_storage" {
  bucket = "${var.workspace_prefix}-root-storage-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-root-storage"
    }
  )
}

# Configure S3 bucket ownership to allow ACLs (required for Databricks)
resource "aws_s3_bucket_ownership_controls" "root_storage" {
  bucket = aws_s3_bucket.root_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"  # ACLs disabled - modern Databricks standard
  }
}

# Enable versioning for the root storage bucket
resource "aws_s3_bucket_versioning" "root_storage" {
  bucket = aws_s3_bucket.root_storage.id

  versioning_configuration {
    status = "Enabled"
  }

  depends_on = [aws_s3_bucket_ownership_controls.root_storage]
}

# Block public access to the root storage bucket
resource "aws_s3_bucket_public_access_block" "root_storage" {
  bucket = aws_s3_bucket.root_storage.id

  block_public_acls       = true
  block_public_policy     = false  # Allow bucket policy for Databricks
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy to allow Databricks direct access (ACLs disabled)
resource "aws_s3_bucket_policy" "root_storage" {
  bucket = aws_s3_bucket.root_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GrantDatabricksAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root"  # Databricks account direct access
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.root_storage.arn,
          "${aws_s3_bucket.root_storage.arn}/*"
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.root_storage]
}

# IAM role for Databricks cross-account access
resource "aws_iam_role" "cross_account_role" {
  name = "${var.workspace_prefix}-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root" # Databricks AWS account ID
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.databricks_account_id
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-cross-account-role"
    }
  )
}

# IAM policy for cross-account role
resource "aws_iam_role_policy" "cross_account_policy" {
  name = "${var.workspace_prefix}-cross-account-policy"
  role = aws_iam_role.cross_account_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "iam:CreateServiceLinkedRole",
          "iam:PutRolePolicy"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.root_storage.arn}/*",
          aws_s3_bucket.root_storage.arn
        ]
      }
    ]
  })
}

# Register credentials configuration with Databricks
resource "databricks_mws_credentials" "this" {
  provider         = databricks.account
  account_id       = var.databricks_account_id
  credentials_name = "${var.workspace_prefix}-credentials"
  role_arn         = aws_iam_role.cross_account_role.arn
}

# Register storage configuration with Databricks
resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.account
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.workspace_prefix}-storage"
  bucket_name                = aws_s3_bucket.root_storage.bucket
}

# Register network configuration with Databricks
resource "databricks_mws_networks" "this" {
  provider           = databricks.account
  account_id         = var.databricks_account_id
  network_name       = "${var.workspace_prefix}-network"
  vpc_id             = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.databricks_vpc[0].id
  subnet_ids         = var.use_existing_vpc ? var.existing_subnet_ids : aws_subnet.private[*].id
  security_group_ids = var.use_existing_vpc ? var.existing_security_group_ids : [aws_security_group.databricks_sg[0].id]
}

# Create the Databricks workspace
resource "databricks_mws_workspaces" "this" {
  provider        = databricks.account
  account_id      = var.databricks_account_id
  workspace_name  = var.workspace_name
  deployment_name = var.workspace_deployment_name
  aws_region      = var.aws_region

  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id               = databricks_mws_networks.this.network_id

  token {
    comment = "Terraform provisioning token"
  }

  depends_on = [
    aws_iam_role_policy.cross_account_policy
  ]
}

# ============================================================
# Unity Catalog Metastore Creation (Optional)
# ============================================================

# Create S3 bucket for Unity Catalog metastore storage
resource "aws_s3_bucket" "metastore" {
  count  = var.create_uc_metastore ? 1 : 0
  bucket = "${var.workspace_prefix}-metastore-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-metastore"
    }
  )
}

# Enable versioning for the metastore bucket
resource "aws_s3_bucket_versioning" "metastore" {
  count  = var.create_uc_metastore ? 1 : 0
  bucket = aws_s3_bucket.metastore[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to the metastore bucket
resource "aws_s3_bucket_public_access_block" "metastore" {
  count  = var.create_uc_metastore ? 1 : 0
  bucket = aws_s3_bucket.metastore[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for Unity Catalog metastore
resource "aws_iam_role" "metastore" {
  count = var.create_uc_metastore ? 1 : 0
  name  = "${var.workspace_prefix}-metastore-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root" # Databricks AWS account ID
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.databricks_account_id
          }
        }
      },
      {
        # Allow role to assume itself (required for Unity Catalog)
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.workspace_prefix}-metastore-role"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.workspace_prefix}-metastore-role"
    }
  )
}

# IAM policy for metastore S3 access
resource "aws_iam_role_policy" "metastore" {
  count = var.create_uc_metastore ? 1 : 0
  name  = "${var.workspace_prefix}-metastore-policy"
  role  = aws_iam_role.metastore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.metastore[0].arn,
          "${aws_s3_bucket.metastore[0].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.root_storage.arn,
          "${aws_s3_bucket.root_storage.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.workspace_prefix}-metastore-role"
        ]
      }
    ]
  })
}

# Create Unity Catalog metastore
resource "databricks_metastore" "this" {
  count         = var.create_uc_metastore ? 1 : 0
  provider      = databricks.account
  name          = var.uc_metastore_name
  storage_root  = "s3://${aws_s3_bucket.metastore[0].bucket}/metastore"
  owner         = "account users"
  region        = var.aws_region
  force_destroy = true

  depends_on = [
    aws_iam_role_policy.metastore
  ]
}

# Create Unity Catalog metastore data access configuration
resource "databricks_metastore_data_access" "this" {
  count        = var.create_uc_metastore ? 1 : 0
  provider     = databricks.account
  metastore_id = databricks_metastore.this[0].id
  name         = "${var.workspace_prefix}-metastore-access"
  aws_iam_role {
    role_arn = aws_iam_role.metastore[0].arn
  }
  is_default = true
}

# ============================================================
# Unity Catalog Metastore Assignment
# ============================================================

# Determine which metastore ID to use (created or existing)
locals {
  metastore_id_to_use = var.create_uc_metastore ? databricks_metastore.this[0].id : var.uc_metastore_id
  should_attach_metastore = var.create_uc_metastore || var.uc_metastore_id != ""
}

# Attach workspace to Unity Catalog metastore
resource "databricks_metastore_assignment" "this" {
  count                = local.should_attach_metastore ? 1 : 0
  provider             = databricks.account
  workspace_id         = databricks_mws_workspaces.this.workspace_id
  metastore_id         = local.metastore_id_to_use
  default_catalog_name = var.default_catalog_name

  depends_on = [
    databricks_metastore_data_access.this
  ]
}

# ============================================================
# Service Principals (Optional)
# ============================================================

# Create service principals for workspace management
resource "databricks_service_principal" "this" {
  count        = var.create_service_principals ? length(var.service_principals) : 0
  provider     = databricks.workspace
  display_name = var.service_principals[count.index].name
  active       = true

  depends_on = [databricks_mws_workspaces.this]
}

# Grant workspace admin privileges to service principals if specified
resource "databricks_permissions" "sp_workspace_admin" {
  count    = var.create_service_principals ? length([for sp in var.service_principals : sp if sp.admin]) : 0
  provider = databricks.workspace

  authorization = "admin"

  access_control {
    service_principal_name = databricks_service_principal.this[count.index].application_id
    permission_level       = "CAN_MANAGE"
  }

  depends_on = [databricks_service_principal.this]
}

# ============================================
# User Management Module
# ============================================

module "users" {
  source = "./modules/users"

  users        = var.users
  groups       = var.groups
  workspace_id = databricks_mws_workspaces.this.workspace_id

  providers = {
    databricks = databricks.workspace
  }

  depends_on = [databricks_mws_workspaces.this]
}

# ============================================
# Unity Catalog Objects Module
# ============================================

module "unity_catalog" {
  source = "./modules/unity-catalog"

  catalogs      = var.catalogs
  metastore_id  = local.metastore_id_to_use
  workspace_id  = databricks_mws_workspaces.this.workspace_id

  providers = {
    databricks = databricks.workspace
  }

  depends_on = [
    databricks_mws_workspaces.this,
    databricks_metastore_assignment.this
  ]
}

# ============================================
# Lakebase Module
# ============================================

module "lakebase" {
  source = "./modules/lakebase"

  database_instances = var.lakebase_database_instances
  database_catalogs  = var.lakebase_database_catalogs

  providers = {
    databricks = databricks.workspace
  }

  depends_on = [
    databricks_mws_workspaces.this,
    databricks_metastore_assignment.this
  ]
}

# ============================================
# SQL Warehouse for Fraud Dashboard
# ============================================

resource "databricks_sql_endpoint" "fraud_dashboard" {
  name             = "${var.workspace_prefix}-fraud-analytics-warehouse"
  cluster_size     = "Small"
  max_num_clusters = 1
  auto_stop_mins   = 20
  
  tags {
    custom_tags {
      key   = "Purpose"
      value = "FraudAnalytics"
    }
  }

  provider = databricks.workspace

  depends_on = [
    databricks_mws_workspaces.this,
    databricks_metastore_assignment.this
  ]
}

# ============================================
# Fraud Dashboard Tables Module
# ============================================

module "fraud_tables" {
  source = "./modules/fraud-tables"

  workspace_url           = "https://${databricks_mws_workspaces.this.workspace_url}"
  sql_warehouse_id        = databricks_sql_endpoint.fraud_dashboard.id
  databricks_cli_profile  = var.databricks_cli_profile

  depends_on_resources = [
    databricks_mws_workspaces.this,
    databricks_metastore_assignment.this,
    module.unity_catalog,
    databricks_sql_endpoint.fraud_dashboard
  ]
}

# ============================================
# Apps Module
# ============================================

module "apps" {
  source = "./modules/apps"

  apps = var.apps

  providers = {
    databricks = databricks.workspace
  }

  depends_on = [
    databricks_mws_workspaces.this,
    databricks_metastore_assignment.this,
    module.lakebase,
    module.fraud_tables
  ]
}

