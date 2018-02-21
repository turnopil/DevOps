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
sqlVersion=5.7
sqlVersionCurrent=$(mysql --version|awk '{ print $5 }'|awk -F\.21, '{ print $1 }')
# set passwrd to mysql
mysqladmin --user=root --password="$DATABASE_PASS" password "$DATABASE_PASS"

if [ "$sqlVersionCurrent" = "$sqlVersion" ]
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

# Make MySQL connectable from outside world without SSH tunnel
echo 'bind-address=0.0.0.0' >> /etc/my.cnf
service mysqld stop
service mysqld start 

# Create DB
echo "Creating databese: bugtrckr"
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE bugtrckr DEFAULT CHARSET = utf8 COLLATE = utf8_unicode_ci;"
# PRIVILEGES
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL ON bugtrckr.* TO 'root'@'%' IDENTIFIED BY '$DATABASE_PASS';"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$DATABASE_PASS';"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Load backup section
echo "Load backed up MySQL database bugtrckr ..."
cd /opt
wget https://s3-eu-west-1.amazonaws.com/turnopil/data-dump.sql > /dev/null 2>&1
# Import settings from application to MySQL database
echo "Set settings to MySQL bugtrckr DATABASE tables"
mysql -u root -p"$DATABASE_PASS" bugtrckr < data-dump.sql

# Add tcp 3306 port to firewall
echo "Allow 3306 port"
# Restart Firewalld service
#systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-port=3306/tcp --permanent
#firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --reload
#firewall-cmd --list-all