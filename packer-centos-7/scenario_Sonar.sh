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

#Add sonar User
groupadd sonar
useradd -c "Sonar System User" -d /opt/sonarqube -g sonar -s /bin/bash sonar
chown -R sonar:sonar /opt/sonarqube
echo "RUN_AS_USER=sonar" >> /opt/sonarqube/bin/sonar.sh

# Add path to DB
sed -i 's/#sonar.jdbc.username=/sonar.jdbc.username='sonar'/g' /opt/sonarqube/conf/sonar.properties
sed -i 's/#sonar.jdbc.password=/sonar.jdbc.password='Prometeus'/g' /opt/sonarqube/conf/sonar.properties
sed -i 's/#sonar.jdbc.url=jdbc:postgresql:\/\/localhost\/sonar/sonar.jdbc.url=jdbc:postgresql:\/\/'mysql.dev'\/sonar/g' /opt/sonarqube/conf/sonar.properties

# Sonar Requirements 
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 2048
echo "vm.max_map_count = 262144">>/etc/sysctl.conf
echo "fs.file-max = 65536">>/etc/sysctl.conf

#setup sonar as service
cat>/etc/systemd/system/sonar.service<<EOF
echo"
[Unit]
Description=SonarQube service
After=network.target network-online.target
Wants=network-online.target

[Service]
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
Type=forking
User=sonar
Group=sonar


[Install]
WantedBy=multi-user.target
EOF

chmod 664 /etc/systemd/system/sonar.service
chmod 755 /etc/init.d/sonar

systemctl start sonar
systemctl enable sonar
systemctl status sonar

setenforce 0

echo "192.168.56.200	mysql.dev">>/etc/hosts
echo "192.168.56.223 	gitlab.dev.com">>/etc/hosts
echo "192.168.56.230	sonar.dev">>/etc/hosts

# Add tcp 9000 port to firewall
echo "Allow 9000 port"
# Restart Firewalld service
#systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-port=9000/tcp --permanent
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --reload
#firewall-cmd --list-all

echo "Done!"