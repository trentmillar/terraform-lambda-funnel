// Render a Cloudformation template to create an SNS topic with the email address subscriptions configured according to the addresses defined in variables.tf
data "template_file" "cloudformation_sns_stack" {
  template = file("${path.module}/templates/sns.tpl")

  vars = {
    display_name  = "cloudwatch-alerts"
    subscriptions = join(",", formatlist("{ \"Endpoint\": \"%s\", \"Protocol\": \"%s\"  }", var.email_addresses, var.protocol))
  }
}

// Execute the Cloudformation template
resource "aws_cloudformation_stack" "sns_topic" {
  name          = "ssm-sns-email-stack"
  template_body = data.template_file.cloudformation_sns_stack.rendered
}

// Create SNS topic & sub to act as a message bus between CW Alarms and our lambda fn's
resource "aws_sns_topic" "sns_message_bus" {
  name = "cloudwatch-to-lambda-message-bus"
}

resource "aws_sns_topic_subscription" "sns_message_bus_lambda" {
  topic_arn = aws_sns_topic.sns_message_bus.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_ec2_alarms.arn
}
