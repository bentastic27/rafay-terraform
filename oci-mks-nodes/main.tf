terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "4.72.0"
    }
  }
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid = var.user_ocid
  fingerprint = var.fingerprint
  private_key = var.private_key
  region = var.region
}

resource "oci_core_instance" "master_instance" {
  count = var.master_count
  availability_domain = var.availability_domain
  compartment_id = var.compartment_id
  display_name = format("%s-%s-%d", var.instance_name_prefix, "master", count.index)
  shape = var.instance_shape

  shape_config {
    ocpus = var.instance_ocpus
    memory_in_gbs = var.instance_memory
  }

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = format("%s-%s-%d", var.instance_name_prefix, "master", count.index)
  }

  source_details {
    source_type = "image"
    source_id = var.image_ocid
    boot_volume_size_in_gbs = var.instance_boot_volume_size
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  state = "RUNNING"
}

resource "oci_core_instance" "worker_instance" {
  count = var.worker_count
  availability_domain = var.availability_domain
  compartment_id = var.compartment_id
  display_name = format("%s-%s-%d", var.instance_name_prefix, "worker", count.index)
  shape = var.instance_shape

  shape_config {
    ocpus = var.instance_ocpus
    memory_in_gbs = var.instance_memory
  }

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = format("%s-%s-%d", var.instance_name_prefix, "worker", count.index)
  }

  source_details {
    source_type = "image"
    source_id = var.image_ocid
    boot_volume_size_in_gbs = var.instance_boot_volume_size
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  state = "RUNNING"
}

output "masters" {
  value = {
    ip: oci_core_instance.master_instance.*.public_ip
    hostname: oci_core_instance.master_instance.*.display_name
  }
}

output "workers" {
  value = {
    ip: oci_core_instance.worker_instance.*.public_ip
    hostname: oci_core_instance.worker_instance.*.display_name
  }  
}