#!/bin/bash

# Script for Odoo File Store Server setup (NFS Server part)

echo "Updating package list..."
sudo apt update -y

echo "Installing NFS Kernel Server..."
sudo apt install nfs-kernel-server -y

echo "Creating Odoo file store directory..."
sudo mkdir -p /mnt/odoo_filestore
sudo chown -R odoo:odoo /mnt/odoo_filestore # Assuming Odoo user will own it
sudo chmod -R 775 /mnt/odoo_filestore

echo "Creating Odoo configuration directory..."
sudo mkdir -p /etc/odoo
sudo chown -R odoo:odoo /etc/odoo # Assuming Odoo user will own it
sudo chmod -R 775 /etc/odoo

echo "Creating Odoo custom addons directory..."
sudo mkdir -p /mnt/odoo_addons
sudo chown -R odoo:odoo /mnt/odoo_addons # Assuming Odoo user will own it
sudo chmod -R 775 /mnt/odoo_addons

echo "Configuring NFS exports..."
# Replace with your Odoo app server IPs
echo "/mnt/odoo_filestore <YOUR_ODOO_APP_SERVER_IP_1>(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/mnt/odoo_filestore <YOUR_ODOO_APP_SERVER_IP_2>(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/etc/odoo <YOUR_ODOO_APP_SERVER_IP_1>(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/etc/odoo <YOUR_ODOO_APP_SERVER_IP_2>(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/mnt/odoo_addons <YOUR_ODOO_APP_SERVER_IP_1>(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/mnt/odoo_addons <YOUR_ODOO_APP_SERVER_IP_2>(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

echo "Exporting NFS directories..."
sudo exportfs -a

echo "Starting and enabling NFS service..."
sudo systemctl start nfs-kernel-server
sudo systemctl enable nfs-kernel-server

echo "NFS server setup complete on File Store Server."
echo "You can now place your odoo.conf and custom addons in /etc/odoo and /mnt/odoo_addons respectively."