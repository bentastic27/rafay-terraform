terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.region
  shared_credentials_file = var.aws_credentials_file
}

resource "aws_instance" "k3s_server" {
  ami           = var.instance_ami_id
  instance_type = var.instance_type
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
    RafayClusterName = var.rafay_cluster_name
    RafayProject = var.rafay_project
  }

  subnet_id = var.subnet_id
  key_name = var.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  security_groups = var.security_groups

  # connection {
  #   type = "ssh"
  #   host = self.public_ip
  #   user = var.instance_ami_user
  #   private_key = "${file(var.instance_keypair_file)}"
  # }

  user_data = <<EOF
#!/bin/bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} INSTALL_K3S_EXEC="server --disable=metrics-server,traefik,servicelb" sh -
  EOF

  provisioner "local-exec" {
    when = create
    command = <<EOT
    until [ "$(curl -k -s -w '%%{http_code}' -o /dev/null https://${self.public_ip}:6443)" -eq 401 ]; do sleep 5; done
    rctl create cluster imported ${var.rafay_cluster_name} -p ${var.rafay_project} -b ${var.rafay_blueprint} -l aws/${var.region} > import.yaml
    scp -o StrictHostKeyChecking=no -i ${var.instance_keypair_file} import.yaml ${var.instance_ami_user}@${aws_instance.k3s_server.public_ip}:/tmp/import.yaml
    ssh -o StrictHostKeyChecking=no -i ${var.instance_keypair_file} ${var.instance_ami_user}@${aws_instance.k3s_server.public_ip}  "sudo kubectl apply -f /tmp/import.yaml"
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = "rctl delete cluster ${self.tags.RafayClusterName} -p ${self.tags.RafayProject} -y && echo '' > import.yaml"
  }
}

output "k3s-info" {
  value = [
    "ssh ${var.instance_ami_user}@${aws_instance.k3s_server.public_ip} -i ${var.instance_keypair_file}",
  ]
}