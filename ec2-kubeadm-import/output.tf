output "kubectl" {
  value = var.install_kubernetes ? "kubectl --kubeconfig ${path.module}/ansible-output/kubeconfig.yaml get nodes" : null
}

output "master_ssh" {
  value = [
    for instance in aws_instance.kubeadm_master : "ssh ${var.instance_ami_user}@${instance.public_ip} -i ${var.instance_keypair_file}"
  ]
}

output "worker_ssh" {
  value = [
    for instance in aws_instance.kubeadm_worker : "ssh ${var.instance_ami_user}@${instance.public_ip} -i ${var.instance_keypair_file}"
  ]
}