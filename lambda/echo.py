#!/usr/bin/env python

import os
import json

import boto3


ec2_client = boto3.client("ec2")


def lambda_handler(event, context):

    print("sns -> " + os.environ.get("sns_arn")
    print("event -> " + json.dumps(event, indent=2))
