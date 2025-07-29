#!/bin/bash

# Script for Odoo Application Server setup (NFS Client part)

echo "Updating package list..."
sudo apt update -y

echo "Installing NFS common package..."
sudo apt install nfs-common -y

echo "Creating mount points..."
sudo mkdir -p /opt/odoo/.local/share/Odoo # This is where Odoo expects its filestore by default
sudo mkdir -p /etc/odoo # For odoo.conf
sudo mkdir -p /opt/odoo/custom_addons # For custom addons

echo "Mounting shared directories from File Store Server..."
# Replace with your File Store Server IP
echo "<YOUR_FILESTORE_SERVER_IP>:/mnt/odoo_filestore /opt/odoo/.local/share/Odoo nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
echo "<YOUR_FILESTORE_SERVER_IP>:/etc/odoo /etc/odoo nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
echo "<YOUR_FILESTORE_SERVER_IP>:/mnt/odoo_addons /opt/odoo/custom_addons nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab

echo "Attempting to mount directories now..."
sudo mount -a

echo "Checking mount status:"
df -h | grep odoo

echo "NFS client setup complete on Odoo Application Server."