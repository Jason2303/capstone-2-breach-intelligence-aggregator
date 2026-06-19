# This KMS Key is attached to the following AWS Services
# IAM USer, Lambda 1,2,3 and 4, StepFunction, Secrets Manager, CloudWatch, CloudTrail, SNS, Athena, GuardDuty, Macie, Config
resource "aws_kms_key" "main_kms_key" {
  description             = "KMS encryption key for services"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Lambda1KMSPolicy"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.lambda_1.name}"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "Lambda2KMSPolicy"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.lambda_2.name}"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "Lambda3KMSPolicy"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.lambda_3.name}"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "Lambda4KMSPolicy"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.lambda_4.name}"
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "StepFunctionKMSPolicy"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.step_function_role.name}"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "SecretsManagerKMSPolicy"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsKMSPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "CloudTrailKMSPolicy"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "SNSKMSPolicy"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "AthenaKMSPolicy"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "GuardDutyKMSPolicy"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "MacieKMSPolicy"
        Effect = "Allow"
        Principal = {
          Service = "macie.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "ConfigKMSPolicy"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      },
    ]
  })
}