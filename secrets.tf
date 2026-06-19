# Secret Manager for API
resource "aws_secretsmanager_secret" "secret_store" {
  name = "breach_intelligence_secret"
  kms_key_id = aws_kms_key.main_kms_key.id
  recovery_window_in_days = 0
}

# Secret Manager IAM Policy
data "aws_iam_policy_document" "secrets_policy" {
  statement {
    sid    = "EnableLambda2toRead"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda_2.arn]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.secret_store.arn]
  }
}

# Poilcy secret attachment
resource "aws_secretsmanager_secret_policy" "secret_store_policy" {
  secret_arn = aws_secretsmanager_secret.secret_store.arn
  policy     = data.aws_iam_policy_document.secrets_policy.json
}

# Secret
resource "aws_secretsmanager_secret_version" "secrets" {
  secret_id     = aws_secretsmanager_secret.secret_store.id
  secret_string = var.hibp_api_key
}