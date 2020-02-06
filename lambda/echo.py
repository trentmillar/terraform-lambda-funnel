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


def lambda_handler(event, context):
    print("sns -> " + os.environ.get("sns_arn"))
    print("event -> " + json.dumps(event, indent=2))

    sns_subscription_arn = os.environ.get("sns_arn")
    instance_id = event["detail"]["instance-id"]

    instance_details = json.dumps(EC2_CLIENT.describe_instances(InstanceIds = [instance_id]), indent=2, default=datetime_converter)
    #print(instance_details)
    
    message = {
        "instance_id": instance_id
    }

    #print(json.dumps(SNS_CLIENT.list_topics(), indent=2))
    
    SNS_CLIENT.publish(
        TargetArn=sns_subscription_arn,
        Subject=f"{instance_id} shutdown",
        Message=json.dumps({"default": instance_details}),
        MessageStructure="json",
    )
