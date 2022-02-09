terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "personal"
  region  = var.AWS_REGION
}

resource "aws_key_pair" "foundry-ssh" {
  key_name   = "foundry-ssh"
  public_key = file(var.FOUNDRY_SSH_PUBLIC_KEY_PATH)

  tags = {
    application = "FoundryVTT"
  }
}

data "cloudinit_config" "server_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/server.yml", {
      foundryDownloadLink: "s3://${aws_s3_bucket.foundryvtt-server.bucket}/${aws_s3_bucket_object.foundry_server_executable.key}"
    })
  }
}

resource "aws_instance" "foundry_server" {
  ami                  = "ami-0d527b8c289b4af7f" //Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.foundry_instance_profile.name

  # VPC
  subnet_id = aws_subnet.foundry_subnet.id

  vpc_security_group_ids = ["${aws_security_group.foundry_allow_tls.id}"]
  key_name               = aws_key_pair.foundry-ssh.id

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("${var.FOUNDRY_SSH_PRIVATE_KEY_PATH}")
  }

  root_block_device {
     volume_size = 40
  }

  # nginx
  user_data = data.cloudinit_config.server_config.rendered

  tags = {
    application = "FoundryVTT"
  }
}

output "foundry_ip_addr" {
  value = aws_instance.foundry_server.public_ip
}

output "foundry_server_adress" {
  value = "s3://${aws_s3_bucket.foundryvtt-server.bucket}/${aws_s3_bucket_object.foundry_server_executable.key}"
}

output "SSH_Command" {
  value = "ssh -i '${var.FOUNDRY_SSH_PRIVATE_KEY_PATH}' ubuntu@${aws_instance.foundry_server.public_ip}"
}

output "Foundry_URL" {
  value = "https://${aws_route53_record.foundry_a_record.name}"
}

