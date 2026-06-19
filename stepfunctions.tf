#Step Function IAM Role
resource "aws_iam_role" "step_function_role" {
  name = "step_function_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "StepFunctionRole"
        Principal = {
          Service = ["states.amazonaws.com"]
        }
      },
    ]
  })

  tags = {
    Name        = "Step Function"
    Environment = "Production"
  }
}

#IAM policy for Step Function
resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "stepfunction_policy"
  path        = "/"
  description = "Policy for StepFunction"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Sid      = "InvokeLambda2"
        Resource = aws_lambda_function.lambda_2.arn
      },
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Sid      = "InvokeLambda3"
        Resource = aws_lambda_function.lambda_3.arn
      },
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Sid      = "InvokeLambda4"
        Resource = aws_lambda_function.lambda_4.arn
      },
    ]
  })
}

# Step Function Role attachment
resource "aws_iam_role_policy_attachment" "attach_invoke" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

# Step Function Resource
# Define Lambda to finish the Step Function
resource "aws_sfn_state_machine" "sfn_step_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.step_function_role.arn
  tracing_configuration {
    enabled = true
  }

  definition = jsonencode({
    Comment       = "Breach Intelligence scan workflow"
    QueryLanguage = "JSONPath"
    StartAt       = "HIBQQuery"
    States = {
      HIBQQuery = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.lambda_2.arn
          "Payload.$"  = "$"
        }
        Next = "DataEnrichment"
      }
      DataEnrichment = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.lambda_3.arn
          "Payload.$"  = "$"
        }
        Next = "ReportGenerator"
      }
      ReportGenerator = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.lambda_4.arn
          "Payload.$"  = "$"
        }
        End = true
      }
    }
  })
}