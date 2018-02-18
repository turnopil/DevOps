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

# Install the plugins needed in Jenkins:
cd /var/lib/jenkins/plugins
rm -R -f ant
rm -R -f credentials
rm -R -f deploy
rm -R -f git-client
rm -R -f git
rm -R -f github-api
rm -R -f github-oauth
rm -R -f github
rm -R -f gcal
rm -R -f google-oauth-plugin
rm -R -f greenballs
rm -R -f javadoc
rm -R -f ldap
rm -R -f mailer 
rm -R -f mapdb-api
rm -R -f maven-plugin
rm -R -f external-monitor-job
rm -R -f oauth-credentials
rm -R -f pam-auth
rm -R -f scm-api
rm -R -f ssh-agent
rm -R -f ssh-credentials
rm -R -f ssh-slaves
rm -R -f subversion
rm -R -f translation
rm -R -f sonar
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ant
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin credentials
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin deploy
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin git-client
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin git
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin github-api
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin github-oauth
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin github
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin gcal
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin google-oauth-plugin
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin greenballs
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin javadoc
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ldap
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin mailer
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin mapdb-api
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin maven-plugin
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin external-monitor-job
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin oauth-credentials
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin pam-auth
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin scm-api
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ssh-agent
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ssh-credentials
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ssh-slaves
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin subversion
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin translation
java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin sonar

# Be sure to change ownership of all of these downloaded plugins to jenkins:jenkins
chown jenkins:jenkins *.hpi
chown jenkins:jenkins *.jpi

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