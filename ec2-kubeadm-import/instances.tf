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
    Name = "${var.resource_name_prefix}-master-${count.index}"
    RafayClusterName = var.rafay_cluster_name
    RafayProject = var.rafay_project
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
    command = <<EOT
      if [ -f ${path.module}/ansible-output/kubeconfig.yaml ]
      then
        export KUBECONFIG=${path.module}/ansible-output/kubeconfig.yaml
        alias etcd-exec="kubectl exec -ti -n kube-system $(kubectl get pods -n kube-system -l component=etcd -o name | head -1 | cut -f2 -d/) -- etcdctl --endpoints https://127.0.0.1:2379 --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt"

        etcd-exec member remove $(etcd-exec member list | grep ${self.public_ip} | cut -f1 -d,)

        kubectl drain ${self.public_ip} --ignore-daemonsets --delete-local-data
        kubectl delete node ${self.public_ip}
      fi
    EOT
  }
}

resource "aws_instance" "kubeadm_worker" {
  count = var.worker_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  associate_public_ip_address = true

  tags = {
    Name = "${var.resource_name_prefix}-worker-${count.index}"
    RafayClusterName = var.rafay_cluster_name
    RafayProject = var.rafay_project
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
    command = <<EOT
      if [ -f ${path.module}/ansible-output/kubeconfig.yaml]
      then
        export KUBECONFIG=${path.module}/ansible-output/kubeconfig.yaml
        kubectl drain ${self.public_ip} --ignore-daemonsets --delete-local-data
        kubectl delete node ${self.public_ip}
      fi
    EOT
  }
}
