
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "./lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda_find_instance" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "echo"
  role             = aws_iam_role.lambda_role.arn
  handler          = "echo.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.7"

  depends_on = [
    "data.archive_file.lambda"
  ]

  environment {
    variables = {
      sns_arn = "todo"
    }
  }
}
