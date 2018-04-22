# Make sure we run with root privileges
if [ $UID != 0 ];
	then
# not root, use sudo
# $0=./script.sh
# $*=treat everything as one word
# exit $?=return in bash
	echo "This script needs root privileges, rerunning it now using sudo!"
	sudo "${SHELL}" "$0" $*
	exit $?
fi
# get real username
if [ $UID = 0 ] && [ ! -z "$SUDO_USER" ];
	then
	USER="$SUDO_USER"
else
	USER="$(whoami)"
fi

# Install
echo "Installing mysql-server"
DATABASE_PASS="a8+?treAvpD"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DATABASE_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DATABASE_PASS"
apt-get -y install mysql-server

echo "Creating database: bugtrckr"
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE bugtrckr DEFAULT CHARSET = utf8 COLLATE = utf8_unicode_ci;"
# PRIVILEGES
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL ON bugtrckr.* TO 'root'@'%' IDENTIFIED BY '$DATABASE_PASS';"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$DATABASE_PASS';"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Load backup section
echo "Load backed up MySQL database bugtrckr ..."
cd /tmp
wget https://s3-eu-west-1.amazonaws.com/turnopil/data-dump.sql > /dev/null 2>&1
# Import settings from application to MySQL database
echo "Set settings to MySQL bugtrckr DATABASE tables"
mysql -u root -p"$DATABASE_PASS" bugtrckr < data-dump.sql