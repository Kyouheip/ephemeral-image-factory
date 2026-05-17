output "ec2_public_ip" {
  value       = aws_instance.sd_server.public_ip
  description = "The public IP address of the WebUI server"
}

output "webui_url" {
  value       = "http://${aws_instance.sd_server.public_ip}:7860"
  description = "The direct URL to access your Stable Diffusion WebUI Forge"
}

output "ssh_command" {
  value       = "ssh -i sd-forge-key.pem ubuntu@${aws_instance.sd_server.public_ip}"
  description = "SSH command to connect to the instance"
}

output "s3_upload_hint" {
  value       = "Before launch, upload your checkpoints to S3: aws s3 cp <your_model>.safetensors s3://${var.s3_bucket_name}/models/"
  description = "CLI hint for uploading models to S3"
}
