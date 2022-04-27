variable "project" {
  type = string
  default = "defaultproject"
}

variable "cluster_name" {
  type = string
  default = "oci-mks"
}

variable "tenancy_ocid" {
    type = string
}

variable "compartment_id" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "private_key" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "region" {
  type = string
  default = "us-phoenix-1"
}

variable "subnet_id" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_private_key_file" {
  type = string
  default = "~/.ssh/id_rsa"
}

variable "instance_name_prefix" {
  type = string
  default = "oci-tf-test"
}

variable "security_groups" {
  type = list(string)
}

variable "master_count" {
  type = number
  default = 1
}

variable "worker_count" {
  type = number
  default = 1
}

variable "instance_shape" {
  type = string
  default = "VM.Standard.E3.Flex"
}

variable "instance_ocpus" {
  type = number
  default = 2
}

variable "instance_memory" {
  type = number
  default = 4
}

variable "instance_boot_volume_size" {
  type = number
  default = 50
}

variable "image_ocid" {
  # ubuntu 20.04 in us-phoenix-1
  # https://docs.oracle.com/en-us/iaas/images/image/0b74ea17-87a5-4f6d-bc7d-dbd62c138f4a/
  type = string
  default = "ocid1.image.oc1.phx.aaaaaaaan3xenf5nz6jgwmseebf2moledl23zsnwekvqok2u3kh77fhketeq"
}

variable "image_user" {
  type = string
  default = "ubuntu"
}

variable "availability_domain" {
  type = string
  default = "PaOl:PHX-AD-1"
}
