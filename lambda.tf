
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "./lambda"
  output_path = "${path.module}/lambda.zip"
}

/* begin lambdas */
resource "aws_lambda_function" "lambda_find_instance" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "ec2-event-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "ec2-event-handler.lambda_handler"
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

resource "aws_lambda_function" "lambda_ec2_alarms" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "ec2-alarm-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "ec2-alarm-handler.lambda_handler"
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

/* end lambdas */

locals {
  functions = [
    aws_lambda_function.lambda_find_instance.function_name,
    aws_lambda_function.lambda_ec2_alarms.function_name
  ]

  arns = [
    aws_lambda_function.lambda_find_instance.arn,
    aws_lambda_function.lambda_ec2_alarms.arn
  ]
}

resource "aws_lambda_permission" "with_sns" {
  count = length(local.functions)

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = local.functions[count.index]
  principal     = "sns.amazonaws.com"
  source_arn    = aws_cloudformation_stack.sns_topic.outputs.ARN
}

resource "aws_sns_topic_subscription" "lambda" {
  count = length(local.arns)

  topic_arn = aws_cloudformation_stack.sns_topic.outputs.ARN
  protocol  = "lambda"
  endpoint  = local.arns[count.index]
}
