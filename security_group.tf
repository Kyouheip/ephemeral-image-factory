//外部からの不正アクセスを遮断し、WebUIポート（7860）をあなたのマイIPのみに絞り込みます。
resource "aws_security_group" "sd_sg" {
  name        = "sd-forge-sg"
  description = "Security group for Stable Diffusion WebUI Forge"
  vpc_id      = aws_vpc.sd_vpc.id

  # WebUIアクセス（指定したIPのみ許可）
  ingress {
    description = "Stable Diffusion WebUI Forge access"
    from_port   = 7860
    to_port     = 7860
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # トラブルシューティング用SSH（指定したIPのみ許可）
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # GitHubやS3、ライブラリ取得用のアウトバウンド全開放
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sd-forge-sg"
  }
}