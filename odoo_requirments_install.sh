#!/bin/bash
################################################################################
#-------------------------------------------------------------------------------
# clone script repo:
# git clone https://github.com/Bk-Soft10/script.git
# open script directory:
# cd script
# Make a new file:
# sudo nano odoo_requirments_install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo_requirments_install.sh
# Execute the script to install Odoo:
# sudo ./odoo_requirments_install.sh
################################################################################
OE_USER="odoo"
OE_HOME="/opt/$OE_USER"
OE_HOME_EXT="/opt/$OE_USER/${OE_USER}-server"
OE_PORT="8069"
OE_VERSION="17.0"
OE_SUPERADMIN="admin@odoo"
GENERATE_RANDOM_PASSWORD="False"
OE_CONFIG="${OE_USER}-server"
LONGPOLLING_PORT="8072"
PY_VENV="True"
PY_VENV_NAME="py3_venv"
PY_VENV_EXT="$OE_HOME/${PY_VENV_NAME}/bin/python"
if [ $PY_VENV = "True" ] && [ PY_VENV_NAME ];then
    PY_VENV_EXT="$OE_HOME/${PY_VENV_NAME}/bin/python"
else
    PY_VENV_EXT=""
fi
##


#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt update -y && sudo apt upgrade -y
sudo apt install net-tools ssh git libpq-dev -y

#--------------------------------------------------
# Python3.12
#--------------------------------------------------
echo -e "\n---- Python3.12 ----"
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update -y
#sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev
sudo apt install python3.12 python3.12-venv python3.12-dev -y


#--------------------------------------------------
# Update Security ports
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo ufw allow 22/tcp
sudo ufw allow 8009:8079/tcp
sudo ufw allow 8009:8079/udp

#--------------------------------------------------
# Create ODOO system user
#--------------------------------------------------

echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
sudo adduser $OE_USER sudo

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt-get install python3 python3-pip -y
sudo apt-get install git python3-cffi build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libpng-dev libjpeg-dev gdebi -y

echo -e "\n---- Install python packages/requirements ----"
sudo -H pip3 install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt
if [ $PY_VENV = "True" ] && [ $PY_VENV_NAME ]; then
    echo -e "* Setup VENV"
    sudo apt install python3.12 python3.12-venv python3.12-dev -y
    sudo su $OE_USER -c "cd $OE_HOME && python3.12 -m venv $PY_VENV_NAME"
    sudo su $OE_USER -c "cd $OE_HOME && source $PY_VENV_NAME/bin/activate && pip3 install --upgrade pip"
    sudo su $OE_USER -c "cd $OE_HOME && source $PY_VENV_NAME/bin/activate && pip3 install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt"
fi

echo -e "\n---- Installing nodeJS NPM and rtlcss for LTR support ----"
sudo apt-get install nodejs npm -y
sudo npm install -g rtlcss

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo "-----------------------------------------------------------"
echo "Done! The Odoo server is ready to install Specifications:"
echo "-----------------------------------------------------------"