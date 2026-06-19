#DATA REPORT BUCKET
# Configure the Data Report bucket
resource "aws_s3_bucket" "data_report_bucket" {
  bucket = "datareports2413"
  # object_lock_enabled = true
  force_destroy = true

  tags = {
    Name        = "Reports"
    Environment = "Production"
  }
}

# Block Public Access to the Data Report Bucket
resource "aws_s3_bucket_public_access_block" "data_report_bucket_block_public_access" {
  bucket = aws_s3_bucket.data_report_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Versioning for the Data Report Bucket
resource "aws_s3_bucket_versioning" "data_report_bucket_versioned" {
  bucket = aws_s3_bucket.data_report_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Data Report Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_report_bucket_encrypted" {
  bucket = aws_s3_bucket.data_report_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main_kms_key.arn
    }
  }
}

#Object Locking for the Data Report Bucket
# resource "aws_s3_bucket_object_lock_configuration" "datareport_object_lock" {
#   bucket = aws_s3_bucket.data_report_bucket.id

#   rule {
#     default_retention {
#       mode = "GOVERNANCE"
#       days = 30
#     }
#   }
# }

# Data Report Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "data_report_lifecycle" {
  bucket = aws_s3_bucket.data_report_bucket.bucket

  rule {
    id = "rule-1"

    status = "Enabled"
    transition {
      days          = 31
      storage_class = "GLACIER"
    }
  }
}



#CLOUDTRAIL BUCKET
# Configure the CloudTrail bucket
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "cloudtraillogs2413"
  # object_lock_enabled = true
  force_destroy = true

  tags = {
    Name        = "CloudTrail"
    Environment = "Production"
  }
}

# Block Public Access to the CloudTrail Bucket
resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_block_public_access" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Versioning for the CloudTrail Bucket
resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioned" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudTrail Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket_encrypted" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main_kms_key.arn
    }
  }
}

# Object Locking for the CloudTrail Bucket
# resource "aws_s3_bucket_object_lock_configuration" "cloudtrail_object_lock" {
#   bucket = aws_s3_bucket.cloudtrail_bucket.id

#   rule {
#     default_retention {
#       mode = "GOVERNANCE"
#       days = 30
#     }
#   }
# }

# CloudTrail Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_bucket_lifecycle" {
  bucket = aws_s3_bucket.cloudtrail_bucket.bucket

  rule {
    id = "rule-1"

    status = "Enabled"
    transition {
      days          = 31
      storage_class = "GLACIER"
    }
  }

}

# CloudTrail Bucket Policy 
data "aws_iam_policy_document" "cloudtrail" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/CloudTrail_Bucket"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_bucket.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/CloudTrail_Bucket"]
    }
  }

  statement {
    sid    = "AWSConfigWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_bucket.arn}/config/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:config:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid    = "AWSConfigAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:config:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail.json
}


# LOGGING BUCKET
# Configure the Logging Bucket
resource "aws_s3_bucket" "access_logs" {
  bucket = "accesslogs2413"
  # object_lock_enabled = true
  force_destroy = true
}

# Bucket Policy for Logging Bucket 
data "aws_iam_policy_document" "access_logs_bucket_policy" {
  statement {
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.access_logs.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# Bucket Policy attachment
resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.access_logs.bucket
  policy = data.aws_iam_policy_document.access_logs_bucket_policy.json
}

# Log Data Report Bucket
resource "aws_s3_bucket_logging" "data_report_bucket" {
  bucket = aws_s3_bucket.data_report_bucket.id

  target_bucket = aws_s3_bucket.access_logs.bucket
  target_prefix = "data-report-logs/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

# Log CloudTrail Bucket
resource "aws_s3_bucket_logging" "cloudtrail_bucket" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  target_bucket = aws_s3_bucket.access_logs.bucket
  target_prefix = "cloudtrail-logs/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

# Log CloudTrail Bucket
resource "aws_s3_bucket_logging" "athena_results_bucket" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  target_bucket = aws_s3_bucket.access_logs.bucket
  target_prefix = "athenabucket-logs/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

# Block Public Access to the Access Logs Bucket
resource "aws_s3_bucket_public_access_block" "access_logs_bucket_block_public_access" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Versioning for the Access Logs Bucket
resource "aws_s3_bucket_versioning" "access_logs_bucket_versioned" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Access Logs Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_bucket_encrypted" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main_kms_key.arn
    }
  }
}

# Object Locking for the Access Logs Bucket
# resource "aws_s3_bucket_object_lock_configuration" "access_logs_object_lock" {
#   bucket = aws_s3_bucket.access_logs.id

#   rule {
#     default_retention {
#       mode = "GOVERNANCE"
#       days = 30
#     }
#   }
# }

# Access Logs Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "access_logs_bucket_lifecycle" {
  bucket = aws_s3_bucket.access_logs.bucket

  rule {
    id = "rule-1"

    status = "Enabled"
    transition {
      days          = 31
      storage_class = "GLACIER"
    }
  }
}


# Configure the Athena bucket
resource "aws_s3_bucket" "athena_results_bucket" {
  bucket = "athenabucket2413"
  # object_lock_enabled = true
  force_destroy = true

  tags = {
    Name        = "Athena Bucket"
    Environment = "Production"
  }
}

# Block Public Access to the Athena Bucket
resource "aws_s3_bucket_public_access_block" "athena_bucket_block_public_access" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Versioning for the Athena Bucket
resource "aws_s3_bucket_versioning" "athena_bucket_versioned" {
  bucket = aws_s3_bucket.athena_results_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Athena Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_bucket_encrypted" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main_kms_key.arn
    }
  }
}

# Object Locking for the Athena Bucket
# resource "aws_s3_bucket_object_lock_configuration" "athena_object_lock" {
#   bucket = aws_s3_bucket.athena_results_bucket.id

#   rule {
#     default_retention {
#       mode = "GOVERNANCE"
#       days = 30
#     }
#   }
# }

# Athena Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "athena_lifecycle" {
  bucket = aws_s3_bucket.athena_results_bucket.bucket

  rule {
    id = "rule-1"

    status = "Enabled"
    transition {
      days          = 31
      storage_class = "GLACIER"
    }
  }
}