output "kubectl" {
  value = [
    "kubectl --kubeconfig ${path.module}/ansible-output/kubeconfig.yaml get nodes"
  ]
}