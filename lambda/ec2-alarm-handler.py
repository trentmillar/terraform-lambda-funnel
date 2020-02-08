#!/usr/bin/env python

import os
import json
import datetime

import boto3


EC2_CLIENT = boto3.client("ec2")
SNS_CLIENT = boto3.client("sns")
CW_CLIENT = boto3.client('cloudwatch')


def datetime_converter(o):
    try:
        if isinstance(o, datetime) and hasattr(o, 'isoformat'):
            return o.isoformat()
        else:
            return o
    except Exception as e:
        return o.strftime("%Y-%m-%dT%H:%M:%S.%f+0000")
        
        
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
        "state": "",
        "description": "",
        "metric_name": "",
        "namespace": "",
        "datetime": "",
        "threshold": "",
        "comparison": "",
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
                "metric_start": end - datetime.timedelta(minutes=10),
                "metric_end": end
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


def lambda_handler(event, context):
    sns_records = event["Records"]

    if len(sns_records) == 0:
        return

    # Assume single record
    cw_message = json.loads(sns_records[0]["Sns"]["Message"])
    cw_details = get_message_details(cw_message)
    
    for instance in cw_details["ec2_instances"]:
        ec2_details = EC2_CLIENT.describe_instances(InstanceIds = [instance["ec2_instance_id"]])
        ec2 = ec2_details["Reservations"][0]["Instances"][0]
        
        instance["ec2_details"] = {
            "ami_id": ec2["ImageId"],
            "instance_type": ec2["InstanceType"],
            "state": ec2["State"]["Name"],
            "launched": str(ec2["LaunchTime"]),
            "private_ips": ec2["PrivateIpAddress"],
            "subnet_id": ec2["SubnetId"],
            "security_groups": ec2["SecurityGroups"],
            "tags": ec2["Tags"]
        }
    
        
    cw_details = json.dumps(cw_details, indent=2, default=datetime_converter)
    
    SNS_CLIENT.publish(
        TopicArn=os.environ.get("sns_arn"),
        Subject="Alarm",
        Message=json.dumps({"default": cw_details}),
        MessageStructure="json",
    )
