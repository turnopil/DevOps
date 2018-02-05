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
echo "Updating system...Please wait 5-10 minutes. There is some problems with repo"
yum update -y --nogpgcheck >/dev/null 2>&1

# Install useful packages
echo "Installing useful packages..."
yum install -y wget --nogpgcheck > /dev/null 2>&1

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
