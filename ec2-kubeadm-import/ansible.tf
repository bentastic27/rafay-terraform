resource "local_file" "ansible_inventory" {
  count = var.install_kubernetes ? 1 : 0

  depends_on = [
    aws_instance.kubeadm_master,
    aws_instance.kubeadm_worker,
    aws_lb.kube_api_nlb
  ]

  filename = "${path.module}/ansible-output/inventory.ini"
  content = templatefile("${path.module}/inventory.tftpl",
    {
      ansible_become_user = "root"
      ansible_user = "ubuntu"
      kubernetes_version = var.kubernetes_version
      containerd_release_version = var.containerd_release_version
      runc_release_version = var.runc_release_version
      ansible_ssh_private_key_file = var.instance_keypair_file
      kube_api_nlb_hostname = aws_lb.kube_api_nlb.dns_name

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
    command = "rm -f ${path.module}/ansible-output/inventory.ini"
  }
}

resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      rm -f ${path.module}/ansible-output/*
      if [ -f ${path.module}/bootstrap.yaml ]; then
        rm ${path.module}/bootstrap.yaml
      fi
    EOT
  }  
}