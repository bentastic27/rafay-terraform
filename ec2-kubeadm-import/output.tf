output "kubectl" {
  value = var.install_kubernetes ? "kubectl --kubeconfig ${path.module}/ansible-output/kubeconfig.yaml get nodes" : null
}