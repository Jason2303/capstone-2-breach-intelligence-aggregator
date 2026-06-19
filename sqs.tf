# Dead letter queue for lambda functions
resource "aws_sqs_queue" "queue_deadletter" {
  name              = "deadletter-queue"
  kms_master_key_id = aws_kms_key.main_kms_key.id
}

# DLQ resource poilicy
resource "aws_sqs_queue_policy" "deadletter_policy" {
  queue_url = aws_sqs_queue.queue_deadletter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaToSendMessage"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.lambda_1.arn,
            aws_iam_role.lambda_2.arn,
            aws_iam_role.lambda_3.arn,
            aws_iam_role.lambda_4.arn
          ]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.queue_deadletter.arn
      }
    ]
  })
}