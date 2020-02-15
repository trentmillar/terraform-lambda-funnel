# Terraform Lambda <- SNS message buss

Simple AWS Lambda/Terrafom project wtih the purpose of funnelling all Cloudwatch Events & Alarms to a central SNS topic which then replays the message to the handler/lambda function. This lambda function can respond to the CW event and coordinate another SNS topic used to notify users/subscribers via email, and other branch process'.
