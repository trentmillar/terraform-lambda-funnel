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
    
    SNS_CLIENT.publish(
        TopicArn=os.environ.get("sns_arn"),
        Subject="Alarm",
        Message="Alarm triggered",
        MessageStructure="json",
    )
