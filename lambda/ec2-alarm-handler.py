#!/usr/bin/env python

import os
import json
import datetime

import boto3


EC2_CLIENT = boto3.client("ec2")
SNS_CLIENT = boto3.client("sns")
CW_CLIENT = boto3.client('cloudwatch')


def datetime_converter(o):
    if isinstance(o, datetime):
        return o.isoformat()
        
        
def parse_prefix(line, fmt):
    try:
        t = datetime.datetime.strptime(line, fmt)
    except ValueError as v:
        if len(v.args) > 0 and v.args[0].startswith('unconverted data remains: '):
            line = line[:-(len(v.args[0]) - 26)]
            t = datetime.datetime.strptime(line, fmt)
        else:
            raise
    return t        


def get_ec2_status(instance_id):
    return


def get_message_details(message):
    detail = {
        "ec2_instances": []
    }
    detail["state"] = message["NewStateValue"]
    detail["description"] = message["AlarmDescription"]
    detail["datetime"] = message["StateChangeTime"]
    detail["threshold"] = message["Trigger"]["Threshold"]
    detail["comparison"] = message["Trigger"]["ComparisonOperator"]
    
    for metric in message["Trigger"]["Metrics"]:
        if "Expression" not in metric:
            detail["metric_name"] = metric["MetricStat"]["Metric"]["MetricName"]
            detail["namespace"] = metric["MetricStat"]["Metric"]["Namespace"]
            
            end = parse_prefix(detail["datetime"], "%Y-%m-%dT%H:%M:%S.%f")
            
            instance_details = {
                "ec2_instance_id": metric["MetricStat"]["Metric"]["Dimensions"][0]["value"],
                "metric_end": end,
                "metric_start": end - datetime.timedelta(minutes=10)
            }
            
            # fetch metrics
            response = CW_CLIENT.get_metric_data(
                MetricDataQueries=[
                    {
                        'Id': metric["Id"],
                        'MetricStat': {
                            'Metric': {
                                'Namespace': metric["MetricStat"]["Metric"]["Namespace"],
                                'MetricName': metric["MetricStat"]["Metric"]["MetricName"],
                                'Dimensions': [
                                    {
                                        "Name": metric["MetricStat"]["Metric"]["Dimensions"][0]["name"],
                                        "Value": metric["MetricStat"]["Metric"]["Dimensions"][0]["value"]
                                    }
                                ]
                            },
                            'Period': metric["MetricStat"]["Period"],
                            'Stat': metric["MetricStat"]["Stat"],
                        },
                        'Label': "CPU Utilization",
                    },
                ],
                StartTime=instance_details["metric_start"],
                EndTime=instance_details["metric_end"]
            )
            
            instance_details["metric_data"] = response["MetricDataResults"][0]["Values"]
            detail["ec2_instances"].append(instance_details)
            
    return detail


"""
{
  "Records": [
    {
      "EventSource": "aws:sns",
      "EventVersion": "1.0",
      "EventSubscriptionArn": "arn:aws:sns:us-west-2:1234567890:ssm-sns-email-stack-EmailSNSTopic-QWERTYUJHGFDS:12356789-b163-4dca-b18f-2a5f74625f41",
      "Sns": {
        "Type": "Notification",
        "MessageId": "123456789-1e05-5541-8890-e752b2790571",
        "TopicArn": "arn:aws:sns:us-west-2:12345678900:ssm-sns-email-stack-EmailSNSTopic-QWERTYU",
        "Subject": "Alarm",
        "Message": "",
        "Timestamp": "2020-02-07T00:07:24.248Z",
        "SignatureVersion": "1",
        "Signature": "2ML4c71cJ8VGaVmkgy36WvEgrfhXL1BQ35Ik6vyodTT3CWu8pyRp2AXmbBPhX/Q8JMs8LOpqPkQjR5D6ElmRzhMsENJuqHvwMwwen1UOBQ2hsGxwwARSRR5nQvIRW/iCdRjRe7yahzr2qPN1Ds+ZAsqrCGkoHllMzRpfkh+m9tF4oFwurgLh35A7B45TAHVJSzQ4MTzfiVucinHgSOkdm2JSju9DsFsCoErRQwzl/cWhuM6ij0D0KI3ALb2bZ1Khjw==",
        "SigningCertUrl": "https://sns.us-west-2.amazonaws.com/SimpleNotificationService-a86cb10b4e1f29c941702d737128f7b6.pem",
        "UnsubscribeUrl": "https://sns.us-west-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-west-2:1234567890:ssm-sns-email-stack-EmailSNSTopic-QWERTYUI:1234567890-b163-4dca-b18f-2a5f74625f41",
        "MessageAttributes": {}
      }
    }
  ]
}
"""


def lambda_handler(event, context):
    sns_records = event["Records"]

    if len(sns_records) == 0:
        return

    # Assume single record
    cw_message = json.loads(sns_records[0]["Sns"]["Message"])
    cw_details = get_message_details(cw_message)

    instance_ids = []
    for instance in cw_details["ec2_instances"]:
        instance_ids.append(instance["ec2_instance_id"])
    
    #ec2_details = EC2_CLIENT.describe_instances(InstanceIds = instance_ids )
    #json.dumps(cw_details, default=datetime_converter)
    
    print(cw_details)
    
    SNS_CLIENT.publish(
        TopicArn=os.environ.get("sns_arn"),
        Subject="Alarm",
        Message=json.dumps({"default": None}),
        MessageStructure="json",
    )
