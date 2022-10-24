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