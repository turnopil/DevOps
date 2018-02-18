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
	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; \
	oraclelicense=accept-securebackup-cookie" \
	http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jre-8u161-linux-x64.rpm > /dev/null 2>&1
	#wget -O java.tar.gz /dev/null 2>> /vagrant/jdk-error.log
	#http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.rpm
	#mkdir /opt/java_jdk
	echo "Extracting JRE package..."
	rpm -ivh jre-8u161-linux-x64.rpm > /dev/null 2>&1
	rm jre-8u161-linux-x64.rpm
		
echo "Java config complete!"

# Set JAVA $HOME directory 
echo "Creating file app.sh"
echo 'export JRE_HOME=/usr/java/jre1.8.0_161' >> /etc/profile.d/app.sh
echo 'export CATALINA_HOME=/usr/apache-tomcat-7.0.85' >> /etc/profile.d/app.sh
echo -e 'export PATH=$JRE_HOME"/bin":$CATALINA_HOME"/bin":$PATH' >> /etc/profile.d/app.sh

#Tomcat section
echo "Tomcat Installing..."
cd /usr
wget http://apache.ip-connect.vn.ua/tomcat/tomcat-7/v7.0.85/bin/apache-tomcat-7.0.85.tar.gz > /dev/null 2>&1
tar zxvf apache-tomcat-7.0.85.tar.gz > /dev/null 2>&1
rm apache-tomcat-7.0.85.tar.gz
chmod -R 755 /usr/apache-tomcat-7.0.85

source /etc/profile.d/app.sh

echo "Done!"