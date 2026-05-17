data "aws_ami" "dlami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning OSS Nvidia Driver AMI GPU PyTorch * (Ubuntu 22.04)*"]
  }
}

resource "aws_instance" "sd_server" {
  ami                    = data.aws_ami.dlami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.sd_public_subnet["a"].id
  vpc_security_group_ids = [aws_security_group.sd_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.sd_key.key_name

  root_block_device {
    volume_size           = 120
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/userdata.sh", {
    s3_bucket = var.s3_bucket_name
  })

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "sd-forge-instance"
  }
}
