
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "./lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda_find_instance" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "echo"
  role             = aws_iam_role.lambda_role.arn
  handler          = "echo.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.7"

  environment {
    variables = {
      sns_arn = aws_cloudformation_stack.sns_topic.outputs.ARN
    }
  }

  depends_on = [
    "data.archive_file.lambda"
  ]
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_find_instance.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_cloudformation_stack.sns_topic.outputs.ARN
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_cloudformation_stack.sns_topic.outputs.ARN
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_find_instance.arn
}
