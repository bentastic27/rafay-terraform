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

resource "aws_instance" "kubeadm_server" {
  ami           = var.instance_ami_id
  instance_type = var.instance_type
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
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

  user_data = <<EOF
#!/bin/bash
apt-get update
apt-get install -y apt-transport-https ca-certificates curl wget

wget -q https://github.com/containerd/containerd/releases/download/v${var.containerd_release_version}/containerd-${var.containerd_release_version}-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-${var.containerd_release_version}-linux-amd64.tar.gz
curl -o /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
systemctl daemon-reload

mkdir -p /etc/containerd
cat <<BLAH | tee /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
BLAH

wget -q https://github.com/opencontainers/runc/releases/download/v${var.runc_release_version}/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

systemctl enable --now containerd

cat <<BLAH | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
BLAH

modprobe overlay
modprobe br_netfilter

cat <<BLAH | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
BLAH

sudo sysctl --system

cat <<BLAH | tee kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
networking:
  podSubnet: 192.168.0.0/16
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
BLAH

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=${var.kubernetes_version}-00 kubeadm=${var.kubernetes_version}-00 kubectl=${var.kubernetes_version}-00
apt-mark hold kubelet kubeadm kubectl

kubeadm init --config kubeadm-config.yaml

kubectl --kubeconfig /etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/v${var.calico_version}/manifests/tigera-operator.yaml
kubectl --kubeconfig /etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/v${var.calico_version}/manifests/custom-resources.yaml
kubectl --kubeconfig /etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/control-plane-
kubectl --kubeconfig /etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-
  EOF

  provisioner "local-exec" {
    when = create
    command = <<EOT
    until [ "$(curl -k -s -w '%%{http_code}' -o /dev/null https://${self.public_ip}:6443/healthz)" -eq 200 ]; do sleep 5; done
    rctl -c ${var.rafay_config_file} create cluster imported ${var.rafay_cluster_name} -p ${var.rafay_project} -b ${var.rafay_blueprint} -l aws/${var.region} > import.yaml
    scp -o StrictHostKeyChecking=no -i ${var.instance_keypair_file} import.yaml ${var.instance_ami_user}@${self.public_ip}:/tmp/import.yaml
    ssh -o StrictHostKeyChecking=no -i ${var.instance_keypair_file} ${var.instance_ami_user}@${self.public_ip}  "sudo kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f /tmp/import.yaml"
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = "rctl -c ${self.tags.cliConfigLocation} delete cluster ${self.tags.RafayClusterName} -p ${self.tags.RafayProject} -y && echo '' > import.yaml"
  }
}

output "kubeadm-info" {
  value = [
    "ssh ${var.instance_ami_user}@${aws_instance.kubeadm_server.public_ip} -i ${var.instance_keypair_file}",
  ]
}