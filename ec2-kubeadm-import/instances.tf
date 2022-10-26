data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "kubeadm_master" {
  count = var.master_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  associate_public_ip_address = true

  tags = {
    Name = "${var.resource_name_prefix}-master"
    RafayClusterName = var.rafay_cluster_name
    RafayProject = var.rafay_project
    cliConfigLocation = var.rafay_config_file
    instanceKeypairFile = var.instance_keypair_file
  }

  key_name = var.key_name

  subnet_id = aws_subnet.subnet.id
  vpc_security_group_ids = [
    aws_security_group.k8s_worker.id
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
    host     = self.public_ip
    private_key = file(self.tags.instanceKeypairFile)
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo kubeadm reset phase remove-etcd-member",
      "sudo kubectl --kubeconfig /etc/kubernetes/admin.conf delete node ${self.public_ip}",
      "sudo kubeadm reset phase cleanup-node"
    ]
  }
}

resource "aws_instance" "kubeadm_worker" {
  count = var.worker_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  associate_public_ip_address = true

  tags = {
    Name = "${var.resource_name_prefix}-worker"
    RafayClusterName = var.rafay_cluster_name
    RafayProject = var.rafay_project
    cliConfigLocation = var.rafay_config_file
    instanceKeypairFile = var.instance_keypair_file
  }

  key_name = var.key_name

  subnet_id = aws_subnet.subnet.id
  vpc_security_group_ids = [
    aws_security_group.k8s_worker.id
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  provisioner "local-exec" {
    when = destroy
    command = "kubectl --kubeconfig ${path.module}/ansible-output/kubeconfig.yaml delete node ${self.public_ip}"
  }
}
