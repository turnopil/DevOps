# Architecture
CPUINFO=`lscpu | grep "Architecture" | awk '{print $2}'`

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

# SetTimeZone
timedatectl set-timezone Europe/Kiev

# Update system
echo "Updating system...Please wait 5-10 minutes. There is some problems with repo"
yum update -y --nogpgcheck >/dev/null 2>&1

# Install useful packages
echo "Installing useful packages..."
yum install -y mc wget nano net-tools git --nogpgcheck > /dev/null 2>&1
echo "Maven Installing..."
yum install -y maven > /dev/null 2>&1

# Check PC specs to see if it's ARM or X86 and grab the correct java version.
CPUINFO=`lscpu | grep "Architecture" | awk '{print $2}'`

# Install Java for X64 PC's
#do_x86() {
echo "Installing & configuring Java...Please wait 5-10 minutes"
if [[ "$CPUINFO" == x86_64 ]]; 
	then
	wget -O java.tar.gz --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.tar.gz > /dev/null 2>> /vagrant/jdk-error.log
#wget -O java.tar.gz --no-check-certificate --no-cookies --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u91-b14/jre-8u91-linux-x64.tar.gz && continue> /dev/null 2>> /vagrant/jdk-error.log
	mkdir /opt/java_jdk
	echo "Extracting JDK package..."
	tar zxvf java.tar.gz -C /opt/java_jdk --strip-components=1 > /dev/null 2>&1
	rm java.tar.gz
	echo "Updating alternatives..."
	update-alternatives --install "/usr/bin/java" "java" "/opt/java_jdk/bin/java" 1
	update-alternatives --install "/usr/bin/jar" "jar" "/opt/java_jdk/bin/jar" 1
	update-alternatives --install "/usr/bin/javac" "javac" "/opt/java_jdk/bin/javac" 1
	update-alternatives --set java /opt/java_jdk/bin/java
	update-alternatives --set jar /opt/java_jdk/bin/jar
	update-alternatives --set javac /opt/java_jdk/bin/javac
	#clear
fi
echo "Java config complete!"
#}
#Set $HOME directory for JAVA
echo "Creating file app.sh"
echo "export JAVA_HOME=/opt/java_jdk" > /etc/profile.d/app.sh
echo "export JRE_HOME=/opt/java_jdk/jre" >> /etc/profile.d/app.sh
echo "export PATH=$JAVA_HOME"/bin":$PATH" >> /etc/profile.d/app.sh
source /etc/profile.d/app.sh
# export MAVEN_HOME=/usr/local/apache-maven-3.5.2

#Check Architecture
#do_java() {
#if [[ "$CPUINFO" == x86_64 ]]; then
#do_x86
#fi
#}

# Install & start MySQL
echo "Installing & configuring MySQL..."
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm  > /dev/null 2>&1
rpm -ivh mysql57-community-release-el7-11.noarch.rpm 
yum install -y mysql-server --nogpgcheck > /dev/null 2>&1
rm mysql57-community-release-el7-11.noarch.rpm

echo "Starting mysql-server"
service mysqld start
echo `service mysqld status | grep active`

# grep 'temporary password' /var/log/mysqld.log
DATABASE_PASS=$(grep 'temporary password' /var/log/mysqld.log|cut -d ":" -f 4|cut -d ' ' -f 2)
#echo $DATABASE_PASS

# Secure_installation_script automation mysql 5.7
echo "Secure_installation_script automation"
#sudo service mysqld stop
mysqladmin --user=root --password="$DATABASE_PASS" password "$DATABASE_PASS"
#mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD(mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"'$DATABASE_PASS') WHERE User='root'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Create DB
echo "Creating databese: tmw and user: tmw"
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE tmw DEFAULT CHARSET = utf8 COLLATE = utf8_unicode_ci;"
#Create a new user with same name as new DB
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