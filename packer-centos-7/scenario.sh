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

# Update system
echo "Updating system...Please wait 5-10 minutes. There is some problems with repo"
yum update -y --nogpgcheck >/dev/null 2>&1
# yum install -y maven > /dev/null 2>&1

# MySQL section
echo "Starting mysql-server"
service mysqld start
echo `service mysqld status | grep active`

# grep 'temporary password' /var/log/mysqld.log
DATABASE_PASS=$(grep 'temporary password' /var/log/mysqld.log|cut -d ":" -f 4|cut -d ' ' -f 2)
# echo $DATABASE_PASS

# Secure_installation_script automation mysql 5.7
echo "Secure_installation_script automation (for MySQL 5.6 only)"
# sudo service mysqld stop
SqlVersion=5.7
SqlVersionCurrent=$(mysql --version|awk '{ print $5 }'|awk -F\.21, '{ print $1 }')
# set passwrd to mysql
mysqladmin --user=root --password="$DATABASE_PASS" password "$DATABASE_PASS"

if [ "$SqlVersionCurrent" = "$SqlVersion" ]
	then
	mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
	echo "MySQL version > 5.6"	
else
# mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD(mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"'$DATABASE_PASS') WHERE User='root'"
	mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
	mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
	mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
	mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
	#echo $SqlVersionCurrent
	#echo "NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO"
fi

# Create DB
echo "Creating databese: tmw and user: tmw"
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE tmw DEFAULT CHARSET = utf8 COLLATE = utf8_unicode_ci;"
# Create a new user with same name as new DB
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL ON tmw.* TO 'tmw'@'localhost' IDENTIFIED BY '$DATABASE_PASS';"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# GIT section
echo "Git clone application..."
cd /opt
git clone https://github.com/if-078/TaskManagmentWizard-NakedSpring-.git > /dev/null 2>&1
cd TaskManagmentWizard-NakedSpring-/src/test/resources

# Import settings from application to MySQL database
echo "Set settings to MySQL tmw DATABASE tables"
mysql -u tmw -p"$DATABASE_PASS" tmw <create_db.sql
mysql -u tmw -p"$DATABASE_PASS" tmw <set_dafault_values.sql

# Write database login & passwd to application config file
# Script was stolen from teammate :)
cd /opt/TaskManagmentWizard-NakedSpring-
echo `chmod -R 755 .`
MCONF=src/main/resources/mysql_connection.properties
sed -i 's/jdbc.username=root/jdbc.username=tmw/g' $MCONF
sed -i 's/jdbc.password=root/jdbc.password='$DATABASE_PASS'/g' $MCONF
echo "Setup complete!"

# Add tcp 8585 port to firewall
echo "Allow 8585 port"
systemctl start firewalld
firewall-cmd --zone=public --add-port=8585/tcp --permanent
firewall-cmd --reload
echo `iptables -S | grep 8585`

# Run application
echo "Run WAR application"
mvn tomcat7:run-war