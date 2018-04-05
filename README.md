# VNGRS IaC Workshop

## Prerequisites

* An Azure account with an active subscription.

* That's all. Thanks to [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/features). :)  

## Steps

* `wget https://github.com/hashicorp/packer/blob/master/contrib/azure-setup.sh`
* `chmod +x azure-setup.sh`
* If you are not using Azure Cloud shell you should run azure-setup.sh `./azure-setup.sh setup`
* Follow the instructions. Don't lose the output. 
* `cp setup.sh.sample setup.sh`
* Update setup.sh accordingly.
* `. ./setup.sh`
* `terraform apply`
