//EC2インスタンスがS3バケットとセキュアに双方向同期（読込・書込）を行える権限を定義します。
resource "aws_iam_role" "ec2_s3_role" {
  name = "sd-forge-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_sync_policy" {
  name        = "sd-forge-s3-sync-policy"
  description = "Allow EC2 to sync items with WebUI S3 Bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [data.aws_s3_bucket.sd_assets.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = ["${data.aws_s3_bucket.sd_assets.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_sync_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "sd-forge-ec2-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}