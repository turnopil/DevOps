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
yum install -y wget mc nano --nogpgcheck > /dev/null 2>&1

# Install & start MySQL
echo "Installing MySQL..."
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm  > /dev/null 2>&1
rpm -ivh mysql57-community-release-el7-11.noarch.rpm 
yum install -y mysql-server --nogpgcheck > /dev/null 2>&1
rm mysql57-community-release-el7-11.noarch.rpm

echo "Done!"