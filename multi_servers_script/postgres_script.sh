#!/bin/bash

# Script for Odoo PostgreSQL Database Server setup

echo "Updating package list..."
sudo apt update -y

echo "Installing PostgreSQL..."
sudo apt install postgresql -y

echo "Configuring PostgreSQL..."

# Allow connections from Odoo application servers (replace with your app server IPs/CIDR)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
echo "host    all             all             <YOUR_ODOO_APP_SERVER_IP_1>/32      md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
echo "host    all             all             <YOUR_ODOO_APP_SERVER_IP_2>/32      md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# Restart PostgreSQL to apply changes
echo "Restarting PostgreSQL service..."
sudo systemctl restart postgresql

# Create a PostgreSQL user for Odoo
read -p "Enter a strong password for the Odoo PostgreSQL user: " ODOO_DB_PASSWORD
sudo -u postgres psql -c "CREATE USER odoo WITH PASSWORD '$ODOO_DB_PASSWORD';"
sudo -u postgres psql -c "ALTER USER odoo WITH SUPERUSER;" # Superuser for simplicity, consider more restricted permissions for production

echo "PostgreSQL setup complete on Database Server."
echo "Remember to note down the Odoo PostgreSQL user password."