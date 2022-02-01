resource "aws_s3_bucket" "foundryVTT-static-assets" {
  bucket        = var.foundryVTT-static-assets-bucket-name
  acl           = "public-read"
  force_destroy = true

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_s3_bucket_policy" "foundry_s3_policy" {
  bucket = aws_s3_bucket.foundryVTT-static-assets.bucket
  policy = data.aws_iam_policy_document.foundry_s3_policy.json
}

data "aws_iam_policy_document" "foundry_s3_policy" {
  statement {
    sid = "PublicReadGetObject"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    effect = "Allow"

    resources = [
      "${aws_s3_bucket.foundryVTT-static-assets.arn}/*",
    ]
  }
}

resource "aws_s3_bucket" "foundryvtt-server" {
  bucket        = "foundryvtt-server"
  acl           = "private"
  force_destroy = true

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_s3_bucket_object" "foundry_server_executable" {
  bucket = aws_s3_bucket.foundryvtt-server.id
  key    = "${var.FOUNDRY_FILENAME}"
  acl    = "private"  # or can be "public-read"
  source = "${var.FOUNDRY_PATH}/${var.FOUNDRY_FILENAME}"
  etag = filemd5("${var.FOUNDRY_PATH}/${var.FOUNDRY_FILENAME}")
}