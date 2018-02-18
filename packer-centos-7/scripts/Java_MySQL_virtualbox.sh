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

# Update system
echo "Updating system..."
yum update -y --nogpgcheck >/dev/null 2>&1

# Install useful packages
echo "Installing useful packages..."
yum install -y wget git mc nano --nogpgcheck > /dev/null 2>&1

# Check PC specs to see if it's ARM or X86 and grab the correct java version.
# CPUINFO=`lscpu | grep "Architecture" | awk '{print $2}'`

# Install Java for X64 PC's
echo "Installing & configuring Java...Please wait 5-10 minutes"
# yum -y remove java*
# yum remove -y java-1.8.0-openjdk
# rm /usr/bin/jar
# rm /etc/alternatives/jar
	cd /opt
	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.rpm > /dev/null 2>&1
	#wget -O java.tar.gz --no-check-certificate --no-cookies --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u91-b14/jre-8u91-linux-x64.tar.gz && continue> /dev/null 2>> /vagrant/jdk-error.log
	#http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.rpm
	#mkdir /opt/java_jdk
	echo "Extracting JDK package..."
	rpm -ivh jdk-8u161-linux-x64.rpm > /dev/null 2>&1
	rm jdk-8u161-linux-x64.rpm
	#tar zxvf java.tar.gz -C /opt/java_jdk --strip-components=1 
	
	echo "Updating alternatives..."
	update-alternatives --install "/usr/bin/java" "java" "/usr/java/jdk1.8.0_161/bin/java" 0
	update-alternatives --install "/usr/bin/jar" "jar" "/usr/java/jdk1.8.0_161/bin/jar" 0
	update-alternatives --install "/usr/bin/javac" "javac" "/usr/java/jdk1.8.0_161/bin/javac" 0
	update-alternatives --set java /usr/java/jdk1.8.0_161/bin/java
	update-alternatives --set jar /usr/java/jdk1.8.0_161/bin/jar
	update-alternatives --set javac /usr/java/jdk1.8.0_161/bin/javac
	
echo "Java config complete!"

# Set JAVA $HOME directory 
echo "Creating file app.sh"
echo 'export JAVA_HOME=/usr/java/jdk1.8.0_161' > /etc/profile.d/app.sh
echo 'export JRE_HOME=/usr/java/jdk1.8.0_161/jre' >> /etc/profile.d/app.sh
echo 'export MAVEN_HOME=/usr/apache-maven-3.5.2/' >> /etc/profile.d/app.sh
echo 'export CATALINA_HOME=/usr/apache-tomcat-7.0.84' >> /etc/profile.d/app.sh
echo -e 'export PATH=$JAVA_HOME"/bin":$MAVEN_HOME"/bin":$CATALINA_HOME"/bin":$PATH' >> /etc/profile.d/app.sh

# export MAVEN_HOME=/usr/local/apache-maven-3.5.2

# Maven section
echo "Maven Installing..."
cd /usr
wget http://apache.ip-connect.vn.ua/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz > /dev/null 2>&1
tar zxvf apache-maven-3.5.2-bin.tar.gz > /dev/null 2>&1
rm apache-maven-3.5.2-bin.tar.gz 
chmod -R 755 /usr/apache-maven-3.5.2/
echo 'The maven version: ' `mvn -v` ' has been installed'
echo -e '\n\n!! Note you must relogin to get mvn in your path!!'
#export MAVEN_HOME=/opt/apache-maven-3.5.2
#source /etc/profile.d/app.sh
#yum install -y maven > /dev/null 2>&1

#Tomcat section
echo "Tomcat Installing..."
cd /usr
wget http://apache.ip-connect.vn.ua/tomcat/tomcat-7/v7.0.85/bin/apache-tomcat-7.0.85.tar.gz > /dev/null 2>&1
tar zxvf apache-tomcat-7.0.85.tar.gz > /dev/null 2>&1
rm apache-tomcat-7.0.85.tar.gz
chmod -R 755 /usr/apache-tomcat-7.0.85

source /etc/profile.d/app.sh
# Install & start MySQL
echo "Installing & configuring MySQL..."
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm  > /dev/null 2>&1
rpm -ivh mysql57-community-release-el7-11.noarch.rpm 
yum install -y mysql-server --nogpgcheck > /dev/null 2>&1
rm mysql57-community-release-el7-11.noarch.rpm

echo "Done!"