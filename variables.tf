//環境に合わせて切り替える変数を定義します。
variable "aws_region" {
  type        = string
  default     = "us-west-2" # GPUスポットの在庫が比較的安定し、価格も最安クラスのオレゴンを指定
  description = "AWS Region to deploy the infrastructure"
}

variable "my_ip" {
  type        = string
  description = "Your public IP address with CIDR block (e.g., '123.45.67.89/32') to restrict WebUI access"
}

variable "s3_bucket_name" {
  type        = string
  description = "Globally unique name for the S3 bucket to store models and outputs"
}

variable "instance_type" {
  type        = string
  default     = "g4dn.xlarge" # NVIDIA T4 (VRAM 16GB) 搭載のハイコスパGPUインスタンス
  description = "EC2 GPU Instance type"
}