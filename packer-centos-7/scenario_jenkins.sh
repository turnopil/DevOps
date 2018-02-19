# Make sure we run with root privileges
if [ $UID != 0 ];
	then
# not root, use sudo
	echo "This script needs root privileges, rerunning it now using sudo!"
	"${SHELL}" "$0" $*
	exit $?
fi
# get real username
if [ $UID = 0 ] && [ ! -z "$SUDO_USER" ];
	then
	USER="$SUDO_USER"
else
	USER="$(whoami)"
fi

CWD=`pwd`

# cli.jar download 
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
# Start the Jenkins service
chkconfig jenkins on
service jenkins restart

# Restart Jenkins to implement the new plugins:
cd $CWD

# Jenkins 8080 port add
# Restart Firewalld service
#systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --reload
#firewall-cmd --list-all 

# Let's start Jenkins
java -jar jenkins-cli.jar -s http://localhost:8080 safe-restart

# Get the ADMIN Initnal Password from below command
#sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo "Done!"