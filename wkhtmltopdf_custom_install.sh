#!/bin/bash
################################################################################
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano wkhtmltopdf_custom_install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x wkhtmltopdf_custom_install.sh
# Execute the script to install Odoo:
# sudo ./wkhtmltopdf_custom_install
################################################################################
INSTALL_WKHTMLTOPDF="True"
if [ "`getconf LONG_BIT`" == "64" ];then
  FILE_WKHTMLTOPDF="wkhtmltox_0.12.6.1-2.$(lsb_release -c -s)_amd64.deb"
else
  FILE_WKHTMLTOPDF="wkhtmltox_0.12.6.1-2.$(lsb_release -c -s)_i386.deb"
fi
WKHTMLTOX_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/${FILE_WKHTMLTOPDF}"
##
WKHTMLTOX_X64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.$(lsb_release -c -s)_amd64.deb"
WKHTMLTOX_X32="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.$(lsb_release -c -s)_i386.deb"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt update -y && sudo apt upgrade -y
sudo apt install libpq-dev xfonts-75dpi

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt install python3 python3-pip -y
sudo apt install git python3-cffi build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libpng-dev libjpeg-dev gdebi -y


#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  #sudo gdebi --n `basename $_url`
  sudo dpkg -i $_url
  sudo apt --fix-broken install

  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  sudo wget $WKHTMLTOX_URL
  #sudo gdebi --n `basename $WKHTMLTOX_URL`
  sudo dpkg -i $FILE_WKHTMLTOPDF
  sudo apt --fix-broken install
  sudo apt install ./$FILE_WKHTMLTOPDF

  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
  echo "Wkhtmltopdf custom installed due to the choice of the user!"
fi
sudo apt install -y openssl build-essential libssl-dev libxrender-dev git-core libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig
echo -e "* Starting wkhtmltopdf Service"
echo "-----------------------------------------------------------"