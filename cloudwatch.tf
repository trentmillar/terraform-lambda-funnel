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
  rule = aws_cloudwatch_event_rule.instances_dropping_out_rule.id
  arn  = aws_lambda_function.lambda_find_instance.arn
  /* role_arn = aws_iam_role.iam_for_cloudwatch_stepfunction.arn */
}

//todo - use sqs
/* resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.this.arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 1
} */

locals {

  # All server instance_id's
  instance_00 = var.create_test_instance ? aws_instance.this[0].id : ""
  instance_01 = var.create_test_instance ? aws_instance.this[1].id : ""

  # Default dimensions
  instance_dimensions = [
    local.instance_00,
    local.instance_01
  ]

}

locals {
  EC2_CPU_TEMPLATE = {
    alarm_name                = "ec2-cpu-utilization"
    comparison_operator       = "LessThanOrEqualToThreshold"
    evaluation_periods        = "1"
    insufficient_data_actions = []
    alarm_actions             = [aws_sns_topic.sns_message_bus.arn]
    threshold                 = "70"
    treat_missing_data        = "ignore"
    datapoints_to_alarm       = 1
    alarm_description         = "This metric monitors ec2 cpu utilization"

    metric_query = [
      {
        id          = "e1"
        expression  = "MAX(METRICS())"
        label       = "Monitors the maximum cpu usage from all m(n) metrics."
        return_data = "true"
      }
    ]

    metric = [
      for i, id in local.instance_dimensions : {
        id          = format("m%s", i),
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = "60"
        stat        = "Average"
        dimensions = {
          InstanceId = id
        }
      }
    ]

    unit_metric   = []
    shared_metric = []
  }
}


locals {

  cloudwatch_metric_alarms = []

  ec2_cpu_replacements_80 = {
    alarm_name        = "ec2-cpu-info-gte80"
    threshold         = "20"
    alarm_description = "This metric monitors ec2 cpu (INFO - 80%)"
  }

  ec2_cpu_replacements_85 = {
    alarm_name        = "ec2-cpu-warn-gte85"
    threshold         = "15"
    alarm_description = "This metric monitors ec2 cpu (WARINING - 85%)"
  }

  ec2_cpu_replacements_90 = {
    alarm_name        = "ec2-cpu-critical-gte90"
    threshold         = "10"
    alarm_description = "This metric monitors ec2 cpu (CRITICAL - 90%)"
  }

  cloudwatch_metric_alarms_w_queries = [local.EC2_CPU_TEMPLATE]
  /*[
    merge(local.EC2_CPU_TEMPLATE, local.ec2_cpu_replacements_80),
    merge(local.EC2_CPU_TEMPLATE, local.ec2_cpu_replacements_85),
    merge(local.EC2_CPU_TEMPLATE, local.ec2_cpu_replacements_90),
  ]*/

}

module "cloudwatch_disk_alarm" {
  source = "github.com/trentmillar/terraform-aws-cloudwatch-module?ref=dev"

  cloudwatch_metric_alarms           = local.cloudwatch_metric_alarms
  cloudwatch_metric_alarms_w_queries = local.cloudwatch_metric_alarms_w_queries
}
