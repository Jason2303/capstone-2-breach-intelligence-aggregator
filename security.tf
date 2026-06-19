# GuardDuty Resource
resource "aws_guardduty_detector" "guardduty" {
  enable = true
  tags = {
    Name        = "GuardDuty"
    Environment = "Production"
  }
}

# GuardDuty S3 Detection Feature
resource "aws_guardduty_detector_feature" "s3_protection" {
  detector_id = aws_guardduty_detector.guardduty.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

# Security Hub Resourcce
resource "aws_securityhub_account" "securityhub" {
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_securityhub_finding_aggregator" "securityhub" {
  linking_mode = "ALL_REGIONS"
}

resource "aws_securityhub_standards_subscription" "securityhub" {
  standards_arn = "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.current.region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.securityhub]
}

# Config Resource
resource "aws_config_configuration_recorder" "config" {
  name     = "aws_config"
  role_arn = aws_iam_role.config.arn


  recording_group {
    all_supported = true

  }

  recording_mode {
    recording_frequency = "CONTINUOUS"

  }
}

# Config Policy Document
data "aws_iam_policy_document" "assume_role_config" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM Policy Document for Config
data "aws_iam_policy_document" "config" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:GetBucketAcl"]
    resources = [
      aws_s3_bucket.cloudtrail_bucket.arn,
      "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
    ]
  }
}

# Config Role
resource "aws_iam_role" "config" {
  name               = "awsconfig-example"
  assume_role_policy = data.aws_iam_policy_document.assume_role_config.json
}

# Config recorder
resource "aws_config_configuration_recorder_status" "config" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.config]
}

# Config Policy Role attachment
resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Delivery Channel for Config
resource "aws_config_delivery_channel" "config" {
  name           = "breach-intelligence-delivery-channel"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.bucket
  s3_key_prefix  = "config"
  s3_kms_key_arn = aws_kms_key.main_kms_key.arn
}

# IAM Role Policy
resource "aws_iam_role_policy" "config" {
  name   = "awsconfig-example"
  role   = aws_iam_role.config.id
  policy = data.aws_iam_policy_document.config.json
}

# Macie Resource
resource "aws_macie2_account" "macie" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

# Classification job for Macie
resource "aws_macie2_classification_job" "macie" {
  job_type = "SCHEDULED"
  name     = "breach-data-classification-job"

  schedule_frequency {
    daily_schedule = true
  }

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [aws_s3_bucket.data_report_bucket.bucket]
    }
  }
  depends_on = [aws_macie2_account.macie]
}