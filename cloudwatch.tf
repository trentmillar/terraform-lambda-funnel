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

/* locals {
  EC2_DISK_SPACE_TEMPLATE = {
    alarm_name                = "ec2-disk-space"
    comparison_operator       = "LessThanOrEqualToThreshold"
    evaluation_periods        = "2"
    insufficient_data_actions = []
    alarm_actions             = //[ aws_cloudformation_stack.sns_topic[0].outputs["ARN"] ]
    threshold                 = "10"
    treat_missing_data        = "notBreaching"
    datapoints_to_alarm       = 2
    alarm_description         = "This metric monitors ec2 disk space"

    metric_query = [
      {
        id          = "e1"
        expression  = "MIN(METRICS())"
        label       = "Monitors the minimum free disk space % from all m(n) metrics."
        return_data = "true"
      }
    ]

    metric = [
      for i, d in local.instance_disk_dimensions : {
        id          = format("m%s", i),
        metric_name = "LogicalDisk % Free Space"
        namespace   = "cw_agent"
        period      = "60"
        stat        = "Average"
        dimensions  = merge(d, { "objectname" : "LogicalDisk" })
      }
    ]

    unit_metric   = []
    shared_metric = []
  }
}


locals {

  cloudwatch_metric_alarms = []

  ec2_disk_space_replacements_80 = {
    alarm_name        = "ec2-disk-space-info-gte80"
    threshold         = "20"
    alarm_description = "This metric monitors ec2 disk space (INFO - 80%)"
  }

  ec2_disk_space_replacements_85 = {
    alarm_name        = "ec2-disk-space-warn-gte85"
    threshold         = "15"
    alarm_description = "This metric monitors ec2 disk space (WARINING - 85%)"
  }

  ec2_disk_space_replacements_90 = {
    alarm_name        = "ec2-disk-space-critical-gte90"
    threshold         = "10"
    alarm_description = "This metric monitors ec2 disk space (CRITICAL - 90%)"
  }

  cloudwatch_metric_alarms_w_queries = [
    merge(local.EC2_DISK_SPACE_TEMPLATE, local.ec2_disk_space_replacements_80),
    merge(local.EC2_DISK_SPACE_TEMPLATE, local.ec2_disk_space_replacements_85),
    merge(local.EC2_DISK_SPACE_TEMPLATE, local.ec2_disk_space_replacements_90),
  ]

}


module "cloudwatch_disk_alarm" {
  source = "github.com/trentmillar/terraform-aws-cloudwatch-module?ref=dev"

  cloudwatch_metric_alarms           = local.cloudwatch_metric_alarms
  cloudwatch_metric_alarms_w_queries = local.cloudwatch_metric_alarms_w_queries
} */
