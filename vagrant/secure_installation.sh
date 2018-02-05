# Make sure we run with root privileges
if [ $UID != 0 ];
	then
# not root, use sudo
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

# Install & start MySQL
echo "Installing & configuring MySQL..."
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm > /dev/null 2>&1
rpm -ivh mysql57-community-release-el7-11.noarch.rpm 
yum install -y mysql-server --nogpgcheck > /dev/null 2>> /vagrant/MySQL-error.log
rm mysql57-community-release-el7-11.noarch.rpm

echo "Starting mysql-server"
service mysqld start
echo `service mysqld status | grep active`

#grep 'temporary password' /var/log/mysqld.log
DATABASE_PASS=$(grep 'temporary password' /var/log/mysqld.log|cut -d ":" -f 4|cut -d ' ' -f 2)

#Secure_installation_script automation mysql 5.7
mysqladmin -u root password "$DATABASE_PASS"
mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
