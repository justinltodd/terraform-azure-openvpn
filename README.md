## Complete Azure Ubuntu 18.04 install of OpenVPN.  
## Terraform automatically installs OpenVPN.


1. Builds Ubuntu 18.04 server and installs Openvpn with latest version of EasyRSA for CA.
2. Ubuntu packages that are install Lighttpd, easyrsa, openvpn, LetsEncrypt for SSL
3. Security Rule for SSH access and Openvpn
4. Build a windows 10 pro desktop. 
5. Security rule for HTTP, HTTPS, WINRM, RDP

## Terraform:

1. Creates Security Groups (Linux and Windows) 
2. Creates Resource Groups 
3. WIll create Hub-Spoke, spoke01.tf, spoke2.tf
4. Creates a management subnet that will eventually be able to access all the hosts. mgmt_spoke.tf
