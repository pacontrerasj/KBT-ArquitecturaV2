data "aws_availability_zones" "available" {
  # checkov:skip=CKV_AWS_394: Check sin impacto de seguridad en el Learner Lab
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "freshbox_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "freshbox-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.freshbox_vpc.id
  tags   = { Name = "freshbox-igw" }
}

resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130: Necesario para nodos EKS sin NAT
  count                   = 2
  vpc_id                  = aws_vpc.freshbox_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "freshbox-public-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.freshbox_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "freshbox-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_default_security_group" "default" {
  # CKV2_AWS_12: Default SG sin reglas
  vpc_id = aws_vpc.freshbox_vpc.id
}

# --- Flow logs a S3: sin rol IAM, permitido en AWS Academy Learner Lab ---
resource "aws_s3_bucket" "flow_logs" {
  # checkov:skip=CKV_AWS_18: Sin bucket secundario para access logging en el lab
  # checkov:skip=CKV_AWS_144: Sin replicación cross-region en el lab
  # checkov:skip=CKV_AWS_145: Sin KMS en el Learner Lab (se usa SSE-S3)
  # checkov:skip=CKV2_AWS_62: El bucket de flow logs no requiere notificaciones de eventos
  bucket_prefix = "freshbox-flow-logs-"
  force_destroy = true
  tags          = { Name = "freshbox-flow-logs" }
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  # checkov:skip=CKV_AWS_145: Sin KMS en el Learner Lab (se usa SSE-S3)
  bucket = aws_s3_bucket.flow_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket                  = aws_s3_bucket.flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  rule {
    id     = "expire-flow-logs"
    status = "Enabled"
    expiration {
      days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.flow_logs.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.flow_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.freshbox_vpc.id
}
