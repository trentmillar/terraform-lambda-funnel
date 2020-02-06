# Render a Cloudformation template to create an SNS topic with the email address subscriptions configured according
# to the addresses defined in variables.tf
data "template_file" "cloudformation_sns_stack" {
  template = file("${path.module}/templates/sns.tpl")

  vars = {
    display_name  = "cloudwatch-alerts"
    subscriptions = join(",", formatlist("{ \"Endpoint\": \"%s\", \"Protocol\": \"%s\"  }", var.email_addresses, var.protocol))
  }
}

# Execute the Cloudformation template
resource "aws_cloudformation_stack" "sns_topic" {
  name          = "ssm-sns-email-stack"
  template_body = data.template_file.cloudformation_sns_stack.rendered
}