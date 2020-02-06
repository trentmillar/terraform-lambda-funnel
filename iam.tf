// https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html

data "aws_iam_policy_document" "trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_cloudwatch_role"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_perm" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// https://docs.aws.amazon.com/directoryservice/latest/admin-guide/create_role.html
// git full access to ec2 instances, needed for boto3.client('ec2')
resource "aws_iam_role_policy_attachment" "execute_ec2" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_policy" "sns_lambda_policy" {
  name = "sns-lambda-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
          {
      "Sid": "AWSConfigSNSPolicy20150201",
      "Action": [
        "SNS:Publish",
        "SNS:ListTopics",
        "SNS:GetTopicAttributes",
        "SNS:CreateTopic",
        "SNS:Subscribe",
        "SNS:DeleteTopic",
        "SNS:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sns_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sns_lambda_policy.arn
}
