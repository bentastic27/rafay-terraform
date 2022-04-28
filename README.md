This repo is a collection of terraform things to spin up clusters with or import into Rafay. Unless otherwise noted, copy `terraform.tfvars.example` to `terraform.tfvars`, make the relavent changes, and do `terraform apply`.

Also, unless noted otherwise these will assume that you configured `rctl` (like with `rctl config init`) and whatever other command line tool (like `aws configure`, etc.). I try to write the code to pull credentials from those. 
