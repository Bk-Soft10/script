#!/bin/bash
################################################################################
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo_install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo_install.sh
# Execute the script to install Odoo:
# ./odoo_install
################################################################################
OE_COPY_USER="odoo_copy"
OE_USER="odoo"
OE_HOME="/opt/$OE_USER"
OE_HOME_EXT="/opt/$OE_USER/${OE_USER}-server"
OE_PORT="8017"
OE_VERSION="17.0"
OE_SUPERADMIN="admin@odoo"
GENERATE_RANDOM_PASSWORD="False"
OE_CONFIG="${OE_COPY_USER}-server"
LONGPOLLING_PORT="8072"
OE_REPO_VERSION="17.0"
OE_CUSTOM_REPO="True"
OE_REPO_URL="https://github.com/Bk-Soft10/kh_tms.git"
OE_REPO_NAME="kh_tms"
OE_REPO_EXT="$OE_HOME/$OE_REPO_NAME"
OE_REPO_REQUIRMENT="https://github.com/Bk-Soft10/kh_tms/blob/${OE_REPO_VERSION}/requirment.txt"
IS_CUSTOM_ADDONS="True"
PATH_CUSTOM_ADDONS="${OE_REPO_EXT}/tms_addons,${OE_REPO_EXT}/custom_addons"
PY_VENV="True"
PY_VENV_NAME="py_venv"
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
sudo apt-get install libpq-dev

#--------------------------------------------------
# Python3.12
#--------------------------------------------------
echo -e "\n---- Python3.12 ----"
apt install software-properties-common -y
add-apt-repository ppa:deadsnakes/ppa
sudo apt update -y
#sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev
sudo apt install python3.12 python3.12-venv python3.12-dev

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - $OE_USER -c "createuser -s $OE_COPY_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt-get install python3 python3-pip
sudo apt-get install git python3-cffi build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libpng-dev libjpeg-dev gdebi -y

echo -e "\n---- Install python packages/requirements ----"
sudo -H pip3 install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt
if [ $PY_VENV = "True" ] && [ $PY_VENV_NAME ]; then
    echo -e "* Setup VENV"
    sudo apt install python3.12 python3.12-venv python3.12-dev
    sudo su $OE_USER -c "cd $OE_HOME && python3.12 -m venv $PY_VENV_NAME"
    sudo su $OE_USER -c "cd $OE_HOME && source $PY_VENV_NAME/bin/activate && pip3 install --upgrade pip"
    if [ $OE_CUSTOM_REPO && $OE_REPO_REQUIRMENT ];then
        sudo su $OE_USER -c "cd $OE_HOME && source $PY_VENV_NAME/bin/activate && pip3 install -r $OE_REPO_REQUIRMENT"
    fi
fi

echo -e "\n---- Installing nodeJS NPM and rtlcss for LTR support ----"
sudo apt-get install nodejs npm -y
sudo npm install -g rtlcss


echo -e "\n---- Create ODOO system user ----"
#sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
sudo adduser $OE_USER sudo

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_COPY_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_COPY_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
if [ $OE_CUSTOM_REPO = "True" ] && [ $OE_REPO_VERSION ] && [ $OE_REPO_URL ] && [ $OE_REPO_EXT ]; then
    echo -e "* clone repo"
    sudo git clone --depth 1 --branch $OE_REPO_VERSION $OE_REPO_URL $OE_REPO_EXT/
fi

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"


sudo touch /etc/${OE_CONFIG}.conf
echo -e "* Creating server config file"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "* Generating random admin password"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
if [ $OE_VERSION > "11.0" ];then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo su root -c "printf 'logfile = /var/log/${OE_COPY_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"

if [ $IS_CUSTOM_ADDONS = "True" ] && [ $PATH_CUSTOM_ADDONS ]; then
    sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/odoo/addons,${OE_HOME_EXT}/addons,${PATH_CUSTOM_ADDONS},\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/odoo/addons,${OE_HOME_EXT}/addons\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/copy_start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/copy_start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
DAEMON=$OE_HOME_EXT/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
VENV=$PY_VENV_EXT
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$VENV \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

echo -e "* Starting Odoo Service"
echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "-----------------------------------------------------------"