resource "aws_iam_role" "foundry_instance_role" {
  name = "foundry_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ]
  })

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_iam_role_policy_attachment" "ec2-s3-policy-attachment" {
  role       = aws_iam_role.foundry_instance_role.name
  policy_arn = aws_iam_policy.s3-policy.arn
}


resource "aws_iam_policy" "s3-policy" {
  name        = "Foundry-s3-read-write"
  description = "Allow ec2 running foundry to write to s3 bucket"
  policy      = data.aws_iam_policy_document.foundry_ec2_writeS3.json
}

data "aws_iam_policy_document" "foundry_ec2_writeS3" {
  statement {
    sid = "FoundryWriteS3"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.foundryVTT-static-assets.arn}/*",
      "${aws_s3_bucket.foundryVTT-static-assets.arn}",
      "${aws_s3_bucket.foundryvtt-server.arn}",
      "${aws_s3_bucket.foundryvtt-server.arn}/*",
    ]
  }
  statement {
    sid = "FoundryListS3"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_instance_profile" "foundry_instance_profile" {
  name = "foundry_instance_profile"
  role = aws_iam_role.foundry_instance_role.name
  tags = {
    application = "FoundryVTT"
  }
}