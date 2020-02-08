
data "archive_file" "ec2_alarm_handler" {
  type        = "zip"
  source_file = "./lambda/ec2-alarm-handler.py"
  output_path = "${path.module}/ec2-alarm-handler.zip"
}

data "archive_file" "ec2_event_handler" {
  type        = "zip"
  source_file = "./lambda/ec2-event-handler.py"
  output_path = "${path.module}/ec2-event-handler.zip"
}


/* begin lambdas */
resource "aws_lambda_function" "lambda_find_instance" {
  filename         = "${path.module}/ec2-event-handler.zip"
  function_name    = "ec2-event-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "ec2-event-handler.lambda_handler"
  source_code_hash = data.archive_file.ec2_event_handler.output_base64sha256
  runtime          = "python3.8" // todo, tm, var out runtime

  environment {
    variables = {
      sns_arn = aws_cloudformation_stack.sns_topic.outputs.ARN
    }
  }

  depends_on = [
    "data.archive_file.ec2_event_handler"
  ]
}

resource "aws_lambda_function" "lambda_ec2_alarms" {
  filename         = "${path.module}/ec2-alarm-handler.zip"
  function_name    = "ec2-alarm-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "ec2-alarm-handler.lambda_handler"
  source_code_hash = data.archive_file.ec2_alarm_handler.output_base64sha256
  runtime          = "python3.8"

  environment {
    variables = {
      sns_arn = aws_cloudformation_stack.sns_topic.outputs.ARN
    }
  }

  depends_on = [
    "data.archive_file.ec2_alarm_handler"
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

resource "aws_lambda_permission" "allow_sns" {
  /* count = length(local.functions) */

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_find_instance.function_name /* local.functions[count.index] */
  principal     = "sns.amazonaws.com"
  source_arn    = aws_cloudformation_stack.sns_topic.outputs.ARN
}

resource "aws_lambda_permission" "allow_sns_replay" {
  /* count = length(local.functions) */

  statement_id  = "AllowExecutionFromSNSReplay"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ec2_alarms.function_name /* local.functions[count.index] */
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_message_bus.arn
}

resource "aws_sns_topic_subscription" "lambda" {
  /* count = length(local.arns) */

  topic_arn = aws_cloudformation_stack.sns_topic.outputs.ARN
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_find_instance.arn /* local.arns[count.index] */

  depends_on = [
    "aws_lambda_function.lambda_find_instance",
    "aws_lambda_function.lambda_ec2_alarms"
  ]
}
