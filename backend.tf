resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-perfectday20"

}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expire_uncurrent_files" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id = "rule-1"
    status = "Enabled"

    noncurrent_version_expiration {
      newer_noncurrent_versions = 10
      noncurrent_days = 7
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform_locks_table"
  billing_mode = "PROVISIONED"
  read_capacity = 1
  write_capacity = 1
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}