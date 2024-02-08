data "aws_iam_policy_document" "lambda_role_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_trust_policy.json
}

# policy for lambda to send logs to CloudWatch
data "aws_iam_policy" "lambda_basic_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "attach_basic_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_basic_policy.arn
}

# policy for lambda to access dynamodb
data "aws_iam_policy_document" "rss_lambda_dynamo_policy_doc" {
  statement {
    sid = "RssLambdaDynamoPolicy"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
    ]

    resources = [
      aws_dynamodb_table.rss_cache.arn
    ]
  }
}

resource "aws_iam_policy" "rss_lambda_dynamo_policy" {
  name   = "rss_lambda_dynamo_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.rss_lambda_dynamo_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.rss_lambda_dynamo_policy.arn
}


data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${var.rss_lambda_project_path}/bootstrap"
  output_path = "${var.rss_lambda_project_path}/lambda-handler.zip"
}

resource "aws_lambda_function" "rss" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  function_name = "rss"
  filename      = data.archive_file.lambda.output_path
  role          = aws_iam_role.lambda_role.arn
  handler = "bootstrap"
  runtime = "provided.al2023"
  architectures = [ "arm64" ]

  source_code_hash = data.archive_file.lambda.output_base64sha256

  logging_config {
    log_format = "JSON"
    application_log_level = "INFO"
    system_log_level = "INFO"
  }

  lifecycle {
    ignore_changes = [ source_code_hash ]
  }
}

resource "aws_lambda_function_url" "rss_url" {
  function_name      = aws_lambda_function.rss.function_name
  authorization_type = "NONE"
}


resource "aws_dynamodb_table" "rss_cache" {
  name         = "rss_cache"
  billing_mode = "PROVISIONED"
  read_capacity = 1
  write_capacity = 1
  hash_key     = "ID"
  attribute {
    name = "ID"
    type = "S"
  }
}

resource "aws_cloudwatch_log_group" "rss_log_group" {
  name = "/aws/lambda/${aws_lambda_function.rss.function_name}"
  retention_in_days = 30
}
