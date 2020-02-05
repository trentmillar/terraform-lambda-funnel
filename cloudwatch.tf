resource "aws_cloudwatch_event_rule" "instances_dropping_out_rule" {
  name          = "dying-instances-rule"
  description   = "Event triggered by started instances dropping to -> shutting down/stopping"
  event_pattern = <<EOF
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "shutting-down",
      "stopping"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "instances_dropping_out_target" {
  rule     = aws_cloudwatch_event_rule.instances_dropping_out_rule.id
  arn      = aws_lambda_function.lambda_find_instance.arn
  /* role_arn = aws_iam_role.iam_for_cloudwatch_stepfunction.arn */
}

//todo - use sqs
/* resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.this.arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 1
} */
