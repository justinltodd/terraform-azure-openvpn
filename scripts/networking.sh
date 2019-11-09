#!/bin/bash

## Get IP address and add it to server.conf
IP=$(ip addr | grep inet | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| head -1)  

## Enable net.ipv4.ip_forward for the system
echo "local" $IP >> /etc/openvpn/server/server.conf
sudo sed -i "/\<net.ipv4.ip_forward\>/c\net.ipv4.ip_forward=1" /etc/sysctl.conf
if ! grep -q '\<net.ipv4.ip_forward\>' /etc/sysctl.conf; then 
    sudo echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf 
fi
sudo echo 1 > /proc/sys/net/ipv4/ip_forward
