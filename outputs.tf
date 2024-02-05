output "lambda_rss_url" {
    description = "the function url of lambda rss"
    value = aws_lambda_function_url.rss_url.function_url
}