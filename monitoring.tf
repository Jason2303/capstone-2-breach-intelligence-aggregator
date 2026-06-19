# CloudTrail Resource
resource "aws_cloudtrail" "cloudtrail_trail" {
  depends_on = [aws_s3_bucket_policy.cloudtrail, aws_sns_topic_policy.sns_policy_security_admin]

  name                          = "CloudTrail_Bucket"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.main_kms_key.arn
  sns_topic_name                = aws_sns_topic.security_admin.name
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_loggroup.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn

  tags = {
    Name        = "CloudTrail"
    Environment = "Production"
  }
}

#CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail_loggroup" {
  name              = "CTLogGroup"
  kms_key_id        = aws_kms_key.main_kms_key.arn
  retention_in_days = 365

  tags = {
    Name        = "CloudWatch"
    Environment = "Production"
  }
}

#IAM execution role for CloudTrail
resource "aws_iam_role" "cloudtrail" {
  name = "execution_role_cloudtrail"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AssumeRole"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "CloudTrail Execution Role"
    Environment = "Production"
  }
}

#IAM policy for CloudTrail
resource "aws_iam_policy" "cloudtrail_policy" {
  name        = "cloudtrail_policy"
  path        = "/"
  description = "Policy for CloudTrail"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:CreateLogStream"
        Effect   = "Allow"
        Sid      = "CreateLogStream"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:*"
      },
      {
        Action   = "logs:PutLogEvents"
        Effect   = "Allow"
        Sid      = "PutLogsEvents"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:*"
      }
    ]
  })
}

# Log Group for API Gateway
resource "aws_cloudwatch_log_group" "http_api_logs" {
  name              = "/aws/v2-api/my-http-api"
  retention_in_days = 30
}

#IAM role and policy attachment for CloudTrail
resource "aws_iam_role_policy_attachment" "cloudtrail_attach" {
  role       = aws_iam_role.cloudtrail.name
  policy_arn = aws_iam_policy.cloudtrail_policy.arn
}

# Resource Policy for CloudWatch allowing GuardDuty and CloudTrail
resource "aws_cloudwatch_log_resource_policy" "cloudwatch" {
  policy_document = data.aws_iam_policy_document.cloudwatch_logs.json
  policy_name     = "breach-intelligence-cloudwatch-policy"
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.waf_loggroup.arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
  statement {
    effect = "Allow"
    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.cloudtrail_loggroup.arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
}