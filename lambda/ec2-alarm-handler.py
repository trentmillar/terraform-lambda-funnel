#!/usr/bin/env python

import os
import json
import datetime

import boto3


EC2_CLIENT = boto3.client("ec2")
SNS_CLIENT = boto3.client("sns")


def datetime_converter(o):
    if isinstance(o, datetime.datetime):
        return o.isoformat()


def get_ec2_status(instance_id):
    return


def get_message_details(message):
    print(message)
    detail = {
        "instances": []
    }
    detail["state"] = message["NewStateValue"]
    detail["description"] = message["AlarmDescription"]
    detail["datetime"] = message["StateChangeTime"]
    detail["threshold"] = message["Trigger"]["Threshold"]
    detail["comparison"] = message["Trigger"]["ComparisonOperator"]
    
    for metric in message["Trigger"]["Metrics"]:
        print(metric)
        if "Expression" not in metric:
            detail["metric_name"] = metric["MetricStat"]["Metric"]["MetricName"]
            detail["namespace"] = metric["MetricStat"]["Metric"]["Namespace"]
            detail["instances"].append(metric["MetricStat"]["Metric"]["Dimensions"][0]["value"])
        
    
    print(detail)
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
    #print("sns -> " + os.environ.get("sns_arn"))
    #print("event -> " + json.dumps(event, indent=2))

    sns_records = event["Records"]

    if len(sns_records) == 0:
        return

    # Assume single record
    cw_message = json.loads(sns_records[0]["Sns"]["Message"])
    cw_details = get_message_details(cw_message)
    
    ec2_details = EC2_CLIENT.describe_instances(InstanceIds = cw_details["instances"] )
    print(json.dumps(ec2_details, indent=2, default=datetime_converter))

    SNS_CLIENT.publish(
        TopicArn=os.environ.get("sns_arn"),
        Subject="Alarm",
        Message=json.dumps({"default": json.dumps(ec2_details, indent=2, default=datetime_converter)}),
        MessageStructure="json",
    )
