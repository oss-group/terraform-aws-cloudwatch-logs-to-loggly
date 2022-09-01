data "aws_iam_policy_document" "cloudwatch-logs-to-loggly-assume-role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "kms_decrypt" {
  statement {
    actions   = ["kms:Decrypt"]
    resources = [
      data.aws_kms_alias.key.target_key_arn
    ]
    condition {
      test     = "StringEquals"
      values   = ["Cloudwatch-to-loggly-${var.lambda_function_suffix}"]
      variable = "kms:EncryptionContext:LambdaFunctionName"
    }
  }
}
data "aws_iam_policy" "CloudWatchFullAccess" {
  arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role" "cloudwatch-logs-to-loggly" {
  name_prefix = "cloudwatch-logs-to-loggly"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch-logs-to-loggly-assume-role.json
  tags = var.tags
  managed_policy_arns = [ data.aws_iam_policy.CloudWatchFullAccess.arn ]
  inline_policy {
    name = "kms_decrypt"
    policy = data.aws_iam_policy_document.kms_decrypt.json
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/Cloudwatch-to-loggly-${var.lambda_function_suffix}"
  retention_in_days = 5
  tags = var.tags
}

resource "aws_lambda_function" "cloudwatch-logs-to-loggly" {
  filename      = "${path.module}/lambda_code/Cloudwatch-to-loggly.zip"
  function_name = "Cloudwatch-to-loggly-${var.lambda_function_suffix}"
  role          = aws_iam_role.cloudwatch-logs-to-loggly.arn
  handler       = "index.handler"
  description = "Sends logs from Cloudwatch logs to Loggly using a Lambda function."
  timeout = 3
  source_code_hash = filebase64sha256("${path.module}/lambda_code/Cloudwatch-to-loggly.zip")
  depends_on = [
    aws_cloudwatch_log_group.lambda
  ]
  runtime = "nodejs12.x"

  memory_size = 128
  tags = var.tags
  environment {
    variables = {
      kmsEncryptedCustomerToken = var.kmsEncryptedCustomerToken
      logglyTags = var.logglyTags
      logglyHostName = var.logglyHostName
    }

  }
  kms_key_arn = var.kms_key_alias == "alias/aws/lambda" ? null : data.aws_kms_alias.key.target_key_arn
}

data "aws_kms_alias" "key" {
  name = var.kms_key_alias
}

data "aws_cloudwatch_log_group" "sub" {
  for_each = toset(var.cloudwatch_groups_to_ship)
  name = each.key
}

data aws_arn "sub" {
  for_each = toset(var.cloudwatch_groups_to_ship)
  arn = data.aws_cloudwatch_log_group.sub[each.key].arn
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch-logs-to-loggly" {
  for_each = toset(var.cloudwatch_groups_to_ship)
  name            = "Cloudwatch-to-loggly-${var.lambda_function_suffix}-${sha1(each.key)}"
  log_group_name  = data.aws_cloudwatch_log_group.sub[each.key].id
  filter_pattern  = var.filter
  destination_arn = aws_lambda_function.cloudwatch-logs-to-loggly.arn
}

resource "aws_lambda_permission" "logging" {
  for_each = toset(var.cloudwatch_groups_to_ship)
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch-logs-to-loggly.function_name
  principal     = "logs.${data.aws_arn.sub[each.key].region}.amazonaws.com"
  source_arn    = "${data.aws_cloudwatch_log_group.sub[each.key].arn}:*"
}