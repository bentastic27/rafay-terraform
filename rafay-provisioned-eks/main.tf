terraform {
  required_providers {
    rafay = {
      version = ">= 0.1"
      source  = "RafaySystems/rafay"
    }
  }
}

provider "rafay" {
  provider_config_file = var.rafay_config_file
}

resource "rafay_eks_cluster" "ekscluster" {
  cluster {
    kind = "Cluster"
    metadata {
      name    = var.name
      project = var.project
      labels = var.labels
    }
    spec {
      type           = "eks"
      blueprint      = "default"
      blueprint_version = "1.12.0"
      cloud_provider = var.cluster.cloud_credentials
      cni_provider   = var.cluster.cni_provider
      proxy_config   = {}
    }
  }
  cluster_config {
    apiversion = "rafay.io/v1alpha5"
    kind       = "ClusterConfig"
    metadata {
      name    = var.name
      region  = var.cluster.region
      version = var.cluster.version
    }
    vpc {
      cidr = var.cluster.cidr
      cluster_endpoints {
        private_access = var.cluster.private_access
        public_access  = var.cluster.public_access
      }
      nat {
        gateway = "Single"
      }
    }
    node_groups {
      name       = var.node_group.name
      ami_family = var.node_group.ami_family
      iam {
        iam_node_group_with_addon_policies {
          image_builder = true
          auto_scaler   = true
          alb_ingress = true
          ebs = true
        }
      }
      ssh {
        allow = var.node_group.ssh_allow
        enable_ssm = true
        public_key_name = var.node_group.ssh_public_key_name
      }
      instance_name = var.node_group.instance_name
      instance_type    = var.node_group.instance_type
      desired_capacity = var.node_group.desired_capacity
      min_size         = var.node_group.min_size
      max_size         = var.node_group.max_size
      max_pods_per_node = 50
      version          = var.cluster.version
      volume_size      = 50
      volume_type      = "gp3"
      private_networking = true
    }
  }
}
