variable "name" {
  type = string
  default = "eks-cluster"
}

variable labels {
  type = map(string)
  default = {}
}

variable "project" {
  type = string
  default = "defaultproject"
}

variable "rafay_config_file" {
  type = string
  default = "~/.rafay/cli/config.json"
  
}

variable "cluster" {
  type = object({
    region = string
    version = string
    cidr = string
    cni_provider = string
    cloud_credentials = string
    private_access = bool
    public_access = bool
    blueprint = string
    blueprint_version = string
  })
  default = {
    region = "us-west-2"
    cidr = "192.168.0.0/16"
    cloud_credentials = "some-credentials"
    cni_provider = "aws-cni"
    private_access = true
    public_access = false
    version = "1.21"
    blueprint = "default"
    blueprint_version = "latest"
  }
}

variable "node_group" {
  type = object({
    name = string
    ami_family = string
    instance_name = string
    instance_type = string
    ssh_allow = bool
    ssh_public_key_name = string
    min_size = number
    max_size = number
    desired_capacity = number
  })
  default = {
    ami_family = "AmazonLinux2"
    name = "ng-1"
    instance_name = "terraform-eks-instance"
    instance_type = "t2.large"
    ssh_allow = false
    ssh_public_key_name = ""
    min_size = 1
    max_size = 2
    desired_capacity = 1
  }
}
