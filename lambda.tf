# IAM Role Policy Document for Trigger Lambda execution
data "aws_iam_policy_document" "lambda_1_iam_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#IAM policy for Lambda1
resource "aws_iam_policy" "lambda1_policy" {
  name        = "lambda1_policy"
  path        = "/"
  description = "Policy for Lambda 1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "states:StartExecution"
        Effect   = "Allow"
        Sid      = "InvokeStateMachine"
        Resource = "arn:${data.aws_partition.current.partition}:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${aws_sfn_state_machine.sfn_step_machine.name}"
      },
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Sid      = "CreateLogGroup"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
      },
      {
        Action   = "logs:CreateLogStream"
        Effect   = "Allow"
        Sid      = "CreateLogStream"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
      },
      {
        Action   = "logs:PutLogEvents"
        Effect   = "Allow"
        Sid      = "PutLogsEvents"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
      },
      {
        Action   = "sqs:SendMessage"
        Effect   = "Allow"
        Sid      = "Sendmessagetosqsdeadletterqueue"
        Resource = "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.queue_deadletter.name}"
      }
    ]
  })
}

# Lambda resource policy to allow API Gateway
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigw.execution_arn}/*/*"
}

# IAM Role for Trigger Lambda execution
resource "aws_iam_role" "lambda_1" {
  name               = "lambda_1_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_1_iam_document.json
}

# Role Attachment for Trigger Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_1-attach" {
  role       = aws_iam_role.lambda_1.name
  policy_arn = aws_iam_policy.lambda1_policy.arn
}

# Package the Trigger Lambda function code
data "archive_file" "lambda_1" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_1.py"
  output_path = "${path.module}/lambda_1.zip"
}

# Trigger Lambda function
resource "aws_lambda_function" "lambda_1" {
  filename      = data.archive_file.lambda_1.output_path
  function_name = "trigger_lambda"
  role          = aws_iam_role.lambda_1.arn
  handler       = "lambda_1.trigger_lambda"
  code_sha256   = data.archive_file.lambda_1.output_base64sha256
  kms_key_arn = aws_kms_key.main_kms_key.arn
  runtime = "python3.13"

  environment {
    variables = {
      ENVIRONMENT = "Production"
      LOG_LEVEL   = "info"
      STATE_MACHINE_ARN = aws_sfn_state_machine.sfn_step_machine.arn
    }
  }

  tracing_config { mode = "Active" }

  dead_letter_config {
    target_arn = aws_sqs_queue.queue_deadletter.arn
  }

  tags = {
    Name = "Trigger Lambda"
    Environment = "Production"
  }
}


# IAM Role Policy Document for HIBP Query Lambda execution
data "aws_iam_policy_document" "lambda_2_iam_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#IAM policy for Lambda2
resource "aws_iam_policy" "lambda2_policy" {
  name        = "lambda2_policy"
  path        = "/"
  description = "Policy for Lambda 2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Sid      = "AllowLambdaToReadSecret"
        Resource = aws_secretsmanager_secret.secret_store.arn
      },
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Sid      = "CreateLogGroup"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
      },
      {
        Action   = "logs:CreateLogStream"
        Effect   = "Allow"
        Sid      = "CreateLogStream"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
      },
      {
        Action   = "logs:PutLogEvents"
        Effect   = "Allow"
        Sid      = "PutLogsEvents"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
      },
      {
        Action   = "sqs:SendMessage"
        Effect   = "Allow"
        Sid      = "Sendmessagetosqsdeadletterqueue"
        Resource = "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.queue_deadletter.name}"
      }
    ]
  })
}

# IAM Role for HIBP Query Lambda execution
resource "aws_iam_role" "lambda_2" {
  name               = "lambda_2_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_2_iam_document.json
}

# Role Attachment for HIBP Query Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_2-attach" {
  role       = aws_iam_role.lambda_2.name
  policy_arn = aws_iam_policy.lambda2_policy.arn
}

# Package the HIBP Query Lambda function code
data "archive_file" "lambda_2" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_2.py"
  output_path = "${path.module}/lambda_2.zip"
}

# HIBP Query Lambda function
resource "aws_lambda_function" "lambda_2" {
  filename      = data.archive_file.lambda_2.output_path
  function_name = "HIBPQuery_lambda"
  role          = aws_iam_role.lambda_2.arn
  handler       = "lambda_2.HIBPQuery_lambda"
  code_sha256   = data.archive_file.lambda_2.output_base64sha256
  kms_key_arn = aws_kms_key.main_kms_key.arn
  runtime = "python3.13"
  timeout = 30

  tracing_config { mode = "Active" }

  environment {
    variables = {
      ENVIRONMENT = "Production"
      LOG_LEVEL   = "info"
      SECRETS_MANAGER_ARN = aws_secretsmanager_secret.secret_store.arn
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.queue_deadletter.arn
  }

  tags = {
    Name = "HIBP Query Lambda"
    Environment = "Production"
  }
}


# IAM Role Policy Document for Data Enrichment Lambda execution
data "aws_iam_policy_document" "lambda_3_iam_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#IAM policy for Lambda3
resource "aws_iam_policy" "lambda3_policy" {
  name        = "lambda3_policy"
  path        = "/"
  description = "Policy for Lambda 3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Sid      = "PutObjectInDataReportBucket"
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.data_report_bucket.bucket}/*"
      },
      {
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Sid      = "ListDataReportBucket"
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.data_report_bucket.bucket}"
      },
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Sid      = "CreateLogGroup"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
      },
      {
        Action   = "logs:CreateLogStream"
        Effect   = "Allow"
        Sid      = "CreateLogStream"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
      },
      {
        Action   = "logs:PutLogEvents"
        Effect   = "Allow"
        Sid      = "PutLogsEvents"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
      },
      {
        Action   = "sqs:SendMessage"
        Effect   = "Allow"
        Sid      = "Sendmessagetosqsdeadletterqueue"
        Resource = "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.queue_deadletter.name}"
      }
    ]
  })
}

# IAM Role for Data Enrichment Lambda execution
resource "aws_iam_role" "lambda_3" {
  name               = "lambda_3_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_3_iam_document.json
}

# Role Attachment for Data Enrichment Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_3-attach" {
  role       = aws_iam_role.lambda_3.name
  policy_arn = aws_iam_policy.lambda3_policy.arn
}

# Package the Data Enrichment Lambda function code
data "archive_file" "lambda_3" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_3.py"
  output_path = "${path.module}/lambda_3.zip"
}

# Data Enrichment Lambda function
resource "aws_lambda_function" "lambda_3" {
  filename      = data.archive_file.lambda_3.output_path
  function_name = "data_enrichment"
  role          = aws_iam_role.lambda_3.arn
  handler       = "lambda_3.data_enrichment"
  code_sha256   = data.archive_file.lambda_3.output_base64sha256
  kms_key_arn = aws_kms_key.main_kms_key.arn
  runtime = "python3.13"
  timeout = 30
  
  tracing_config { mode = "Active" }

  environment {
    variables = {
      ENVIRONMENT = "Production"
      LOG_LEVEL   = "info"
      BUCKET = aws_s3_bucket.data_report_bucket.bucket
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.queue_deadletter.arn
  }

  tags = {
    Name = "Data Enrichment Lambda"
    Environment = "Production"
  }
}


# IAM Role Policy Document for Report Generator Lambda execution
data "aws_iam_policy_document" "lambda_4_iam_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#IAM policy for Lambda4
resource "aws_iam_policy" "lambda4_policy" {
  name        = "lambda4_policy"
  path        = "/"
  description = "Policy for Lambda 4"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3DataAndResultsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.data_report_bucket.bucket}",
          "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.data_report_bucket.bucket}/*",
          "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.athena_results_bucket.bucket}",
          "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.athena_results_bucket.bucket}/*"
        ]
      },
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Sid      = "SendMessagetoSNSUser"
        Resource = "arn:${data.aws_partition.current.partition}:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_sns_topic.sns_user.name}"
      },
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Sid      = "SendMessagetoSecurityAdmin"
        Resource = "arn:${data.aws_partition.current.partition}:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_sns_topic.security_admin.name}"
      },
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Sid      = "CreateLogGroup"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
      },
      {
        Action   = "logs:CreateLogStream"
        Effect   = "Allow"
        Sid      = "CreateLogStream"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
      },
      {
        Action   = "logs:PutLogEvents"
        Effect   = "Allow"
        Sid      = "PutLogsEvents"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
      },
      {
        Action   = "sqs:SendMessage"
        Effect   = "Allow"
        Sid      = "Sendmessagetosqsdeadletterqueue"
        Resource = "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.queue_deadletter.name}"
      }
    ]
  })
}

# IAM Role for Report Generator Lambda execution
resource "aws_iam_role" "lambda_4" {
  name               = "lambda_4_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_4_iam_document.json
}

# Role Attachment for Report Generator Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_4-attach" {
  role       = aws_iam_role.lambda_4.name
  policy_arn = aws_iam_policy.lambda4_policy.arn
}

# Package the Report Generator Lambda function code
data "archive_file" "lambda_4" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_4.py"
  output_path = "${path.module}/lambda_4.zip"
}

# Report Generator Lambda function
resource "aws_lambda_function" "lambda_4" {
  filename      = data.archive_file.lambda_4.output_path
  function_name = "reportgenerator_lambda"
  role          = aws_iam_role.lambda_4.arn
  handler       = "lambda_4.reports_lambda"
  code_sha256   = data.archive_file.lambda_4.output_base64sha256
  kms_key_arn = aws_kms_key.main_kms_key.arn
  runtime = "python3.13"
  timeout = 30
  tracing_config { mode = "Active" }

  environment {
    variables = {
      ENVIRONMENT = "Production"
      LOG_LEVEL   = "info"
      SNS_USER_ARN      = aws_sns_topic.sns_user.arn
      SNS_ADMIN_ARN     = aws_sns_topic.security_admin.arn
      S3_BUCKET_NAME    = aws_s3_bucket.data_report_bucket.bucket
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.queue_deadletter.arn
  }

  tags = {
    Name = "Report Generator Lambda"
    Environment = "Production"
    
  }
}


