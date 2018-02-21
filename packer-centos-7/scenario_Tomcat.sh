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

# MV Server.xml & User.xml
$CATALINA_HOME/bin/shutdown.sh
cd /opt
wget https://s3-eu-west-1.amazonaws.com/turnopil/server.xml
wget https://s3-eu-west-1.amazonaws.com/turnopil/tomcat-users.xml
chmod 755 *.xml 
mv *.xml /$CATALINA_HOME/conf/
$CATALINA_HOME/bin/startup.sh 

# Add tcp 80 port to firewall
echo "Allow 80 port"
# Restart Firewalld service
#systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --reload
#firewall-cmd --list-all

echo "Done!"