#SNS Topic for Security Admin
resource "aws_sns_topic" "security_admin" {
  name              = "securityadmin"
  kms_master_key_id = aws_kms_key.main_kms_key.arn
}

#SNS Subscription for Security Admin
resource "aws_sns_topic_subscription" "security_email" {
  topic_arn = aws_sns_topic.security_admin.arn
  protocol  = "email"
  endpoint  = var.security_email
}

#SNS Topic Policy Document for Security Admin
resource "aws_sns_topic_policy" "sns_policy_security_admin" {
  arn = aws_sns_topic.security_admin.arn

  policy = data.aws_iam_policy_document.security_admin_topic_policy.json
}

#Policy document for Security Admin SNS Topic
data "aws_iam_policy_document" "security_admin_topic_policy" {
  policy_id = "SNSTopicforSecurityAdmin"

  #Statement for CloudTrail
  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/CloudTrail_Bucket",
      ]
    }

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.security_admin.arn,
    ]

    sid = "ToAllowCloudTrail"
  }

  #Statement for EventBridge sending GuardDuty Findings
  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:${data.aws_partition.current.partition}:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:event-bus/event-bus",
      ]
    }

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.security_admin.arn,
    ]

    sid = "ToAllowGuardDuty"
  }

  #Statement for CloudWatch Alarms
  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:${data.aws_partition.current.partition}:cloudwatch:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:alarm:*",
      ]
    }

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.security_admin.arn,
    ]

    sid = "ToAllowCloudWatch"
  }

  # Statement for Report Generator Lambda
  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:report_generator_lambda",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda_4.arn]
    }

    resources = [
      aws_sns_topic.security_admin.arn,
    ]

    sid = "ToAllowLambdaFunction"
  }

}


#SNS Topic for User
resource "aws_sns_topic" "sns_user" {
  name              = "user"
  kms_master_key_id = aws_kms_key.main_kms_key.arn
}

#SNS Subscription for User
resource "aws_sns_topic_subscription" "user_email" {
  topic_arn = aws_sns_topic.sns_user.arn
  protocol  = "email"
  endpoint  = var.user_email
}

#SNS Topic Policy Document for User
resource "aws_sns_topic_policy" "sns_policy_user" {
  arn = aws_sns_topic.sns_user.arn

  policy = data.aws_iam_policy_document.sns_user.json
}

#Policy document for User SNS Topic
data "aws_iam_policy_document" "sns_user" {
  policy_id = "SNSTopicforUser"


  #Statement for Report Generator Lambda
  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:report_generator_lambda",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda_4.arn]
    }

    resources = [
      aws_sns_topic.sns_user.arn,
    ]

    sid = "ToAllowLambdaFunction"
  }
}