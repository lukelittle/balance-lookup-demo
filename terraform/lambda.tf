# ---------------------------------------------------------------------------
# Niner National Bank - Branch Operations - Balance-lookup API
# A single Lambda function behind a public Function URL.
# ---------------------------------------------------------------------------

locals {
  name = "nnb-balance-${var.team_name}"
}

# AWS Academy: IAM role creation is blocked, so we look up the pre-made LabRole.
data "aws_iam_role" "lab" {
  count = var.use_lab_role ? 1 : 0
  name  = "LabRole"
}

# Outside Academy: create a minimal execution role (portable path).
resource "aws_iam_role" "lambda" {
  count = var.use_lab_role ? 0 : 1
  name  = "${local.name}-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

locals {
  lambda_role_arn = var.use_lab_role ? data.aws_iam_role.lab[0].arn : aws_iam_role.lambda[0].arn
}

data "archive_file" "app" {
  type        = "zip"
  source_dir  = "${path.module}/../app"
  output_path = "${path.module}/.build/app.zip"
  excludes    = ["__pycache__", "tests"]
}

# Explicit log group so we control retention (and so it is destroyed with the stack).
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "balance" {
  function_name    = local.name
  description      = "NNB balance lookup (ITCS 5010 week 1)"
  role             = local.lambda_role_arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.app.output_path
  source_code_hash = data.archive_file.app.output_base64sha256
  timeout          = var.lambda_timeout_seconds
  memory_size      = 128

  environment {
    variables = {
      FAILURE_RATE     = tostring(var.failure_rate)
      ADDED_LATENCY_MS = tostring(var.added_latency_ms)
      TEAM_NAME        = var.team_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_function_url" "balance" {
  function_name      = aws_lambda_function.balance.function_name
  authorization_type = "NONE" # demo only - a real bank API would use IAM or Cognito auth
}

# Public function URLs need BOTH statements (AWS change, Oct 2025).
resource "aws_lambda_permission" "url_invoke_url" {
  statement_id           = "AllowPublicFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.balance.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "url_invoke_function" {
  statement_id             = "AllowInvokeViaFunctionUrl"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.balance.function_name
  principal                = "*"
  invoked_via_function_url = true
}
