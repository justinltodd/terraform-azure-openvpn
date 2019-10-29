# pacman_terraform_dev
Terraform scripts to create Windows 10 and Ubuntu 18.04 LTS

## Steps for use

1. cd 'OS' select which OS
2. Update variables.tf credentials
3. terraform init
4. terraform apply

##-------------------##

# Azure OpenVPN
Terraform scripts to create a quick OpenVPN server in azure.

## Steps for use

1. For Azure, be sure you have the Azure CLI installed and complete an `az login`
2. Create your SSH keys:

    `cd terraform_pacman_dev`

    `ssh-keygen -N '' -f ./certs/ovpn`

3. Edit your own `cert_details` (use `cert_details.sample` as template)
4. In the cloud provider you're using, edit the region in `variables.tf` as needed
5. The new `.ovpn` file will be copied from new instance into `cert_details`. Open with your OpenVPN client.
