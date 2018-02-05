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

yum install -y wget 
# Install & start MySQL
echo "Installing & configuring MySQL..."
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm  > /dev/null 2>&1
rpm -ivh mysql57-community-release-el7-11.noarch.rpm 
yum install -y mysql-server --nogpgcheck 
rm mysql57-community-release-el7-11.noarch.rpm

echo "Starting mysql-server"
service mysqld start
echo `service mysqld status | grep active`

#grep 'temporary password' /var/log/mysqld.log
DATABASE_PASS=$(grep 'temporary password' /var/log/mysqld.log|cut -d ":" -f 4|cut -d ' ' -f 2)
echo $DATABASE_PASS

echo "Secure_installation_script automation"
#Secure_installation_script automation mysql 5.7
#sudo service mysqld stop
mysqladmin --user=root --password="$DATABASE_PASS" password "$DATABASE_PASS"
#mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD(mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"'$DATABASE_PASS') WHERE User='root'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

echo "Creating databese: tmw and user: tmw"
#Create DB
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE tmw DEFAULT CHARSET = utf8 COLLATE = utf8_unicode_ci;"
#Create a new user with same name as new DB
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL ON tmw.* TO 'tmw'@'localhost' IDENTIFIED BY '$DATABASE_PASS';"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

#GIT section
echo "Git clone application..."
cd /opt
yum install -y git
git clone https://github.com/if-078/TaskManagmentWizard-NakedSpring-.git
cd TaskManagmentWizard-NakedSpring-/src/test/resources

#Import settings from application to MySQL database
echo "Set settings to MySQL tmw DATABASE tables"
mysql -u tmw -p"$DATABASE_PASS" tmw <create_db.sql
mysql -u tmw -p"$DATABASE_PASS" tmw <set_dafault_values.sql

#Wright database login & passwd to aaplication config file
cd /opt/TaskManagmentWizard-NakedSpring-
MCONF=src/main/resources/mysql_connection.properties
sed -i 's/jdbc.username=root/jdbc.username=tmw/g' $MCONF
sed -i 's/jdbc.password=root/jdbc.password='$DATABASE_PASS'/g' $MCONF

#GRANT ALL PRIVILEGES ON *.* TO 'myNewUser'@'localhost';
#GRANT ALL PRIVILEGES ON *.* TO 'myNewUser'@'%';

#firewall-cmd --zone=public --add-port=8585/tcp --permanent
#firewall-cmd --reload

