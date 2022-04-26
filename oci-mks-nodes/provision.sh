#!/bin/bash

terraform apply

cp cluster-base.yaml cluster.yaml

for masterip in $(terraform show -json | jq -r '.values.root_module.resources | .[] | select(.name == "master_instance") | .values.display_name + "," + .values.public_ip')
do
  echo "    - hostname: $(echo $masterip | cut -f1 -d,)" >> cluster.yaml
  echo "      ipAddress: $(echo $masterip | cut -f2 -d,)" >> cluster.yaml
  echo "      sshPrivateKeyPath: $(ls ~/.ssh/id_rsa)" >> cluster.yaml
  echo "      sshPort: 22" >>cluster.yaml
  echo "      sshUserName: ubuntu" >> cluster.yaml
  echo "      roles: [Master]" >> cluster.yaml
done

for workerip in $(terraform show -json | jq -r '.values.root_module.resources | .[] | select(.name == "worker_instance") | .values.display_name + "," + .values.public_ip')
do
  echo "    - hostname: $(echo $workerip | cut -f1 -d,)" >> cluster.yaml
  echo "      ipAddress: $(echo $workerip | cut -f2 -d,)" >> cluster.yaml
  echo "      sshPrivateKeyPath: $(ls ~/.ssh/id_rsa)" >> cluster.yaml
  echo "      sshPort: 22" >>cluster.yaml
  echo "      sshUserName: ubuntu" >> cluster.yaml
  echo "      roles: [Worker]" >> cluster.yaml
done

rctl create cluster mks -p benhealey -f cluster.yaml