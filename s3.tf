// 既存のS3バケットを参照（バケット自体はTerraform管理外・destroy時も残る）
data "aws_s3_bucket" "sd_assets" {
  bucket = var.s3_bucket_name
}
