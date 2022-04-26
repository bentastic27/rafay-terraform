#!/bin/bash
terraform destroy
rctl delete cluster $(grep cluster_name terraform.tfvars | awk '{print $3}'| cut -f2 -d\")
rm cluster.yaml