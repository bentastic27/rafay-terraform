Requires ansible (`brew install ansible`) and kubernetes.core and community.general modules (`ansible-galaxy collection install kubernetes.core community.general`)

This will import the cluster to Rafay (configured with `rafay_config_file`) unless `rafay_import` is set to false.