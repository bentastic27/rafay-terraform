terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    rafay = {
      source = "RafaySystems/rafay"
      version = "1.1.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.region
  shared_credentials_file = var.aws_credentials_file
}

provider "rafay" {
  provider_config_file = var.rafay_config_file
}

resource "aws_instance" "kubeadm_master" {
  count = var.master_count

  ami           = var.instance_ami_id
  instance_type = var.instance_type
  associate_public_ip_address = true

  tags = {
    Name = "${var.instance_name}-master"
    RafayClusterName = var.rafay_cluster_name
    RafayProject = var.rafay_project
    cliConfigLocation = var.rafay_config_file
  }

  subnet_id = var.subnet_id
  key_name = var.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  security_groups = var.security_groups

}

resource "aws_instance" "kubeadm_worker" {
  count = var.worker_count

  ami           = var.instance_ami_id
  instance_type = var.instance_type
  associate_public_ip_address = true

  tags = {
    Name = "${var.instance_name}-worker"
    RafayClusterName = var.rafay_cluster_name
    RafayProject = var.rafay_project
    cliConfigLocation = var.rafay_config_file
  }

  subnet_id = var.subnet_id
  key_name = var.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  security_groups = var.security_groups
}

resource "local_file" "ansible_inventory" {
  depends_on = [
    aws_instance.kubeadm_master,
    aws_instance.kubeadm_worker
  ]

  filename = "${path.module}/ansible-output/inventory.ini"
  content = templatefile("${path.module}/inventory.tftpl",
    {
      ansible_become_user = "root"
      ansible_user = "ubuntu"
      kubernetes_version = var.kubernetes_version
      containerd_release_version = var.containerd_release_version
      runc_release_version = var.runc_release_version
      calico_version = var.calico_version
      ansible_ssh_private_key_file = var.instance_keypair_file

      masters = aws_instance.kubeadm_master[*].public_ip
      workers = aws_instance.kubeadm_worker[*].public_ip
    }
  )

  file_permission = "0644"
  directory_permission = "0755"

  provisioner "local-exec" {
    when = create
    command = "ansible-playbook -i ${path.module}/ansible-output/inventory.ini ${path.module}/playbook.yaml"
  }

    provisioner "local-exec" {
    when = destroy
    command = "rm -f ${path.module}/ansible-output/*"
  }
}

resource "rafay_import_cluster" "terraform-importcluster" {
  count = var.rafay_import ? 1 : 0

  depends_on = [
    local_file.ansible_inventory
  ]
  clustername       = var.rafay_cluster_name
  projectname       = var.rafay_project
  blueprint         = var.rafay_blueprint
  kubeconfig_path   = "ansible-output/kubeconfig.yaml"
}
