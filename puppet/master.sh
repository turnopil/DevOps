#!/usr/bin/env bash
# This bootstraps PuppetServer on CentOS 7.x
# It has been tested on CentOS 7.0 64bit

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
# check if puppet already installed 
if which puppet > /dev/null 2>&1; then
  echo "Puppet is already installed."
  exit 0
fi

# Update system
echo "Updating system..."
yum update -y --nogpgcheck > /dev/null 2>&1

# -- edit hosts --
cat>>/etc/hosts<<EOF
172.10.10.10 puppetmaster.dev
172.10.20.10 mysqlmaster.dev
172.10.30.10 mysqlslave.dev
EOF

# Install puppet labs repo
rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm > /dev/null 2>&1

# Install the Puppet server
echo "Installing the Puppet server"
yum install -y puppetserver > /dev/null 2>&1

sed -i 's|-Xms2g -Xmx2g|-Xms512m -Xmx512m|g' /etc/sysconfig/puppetserver

cat>/etc/puppetlabs/puppet/puppet.conf<<EOF
[master]
vardir = /opt/puppetlabs/server/data/puppetserver
logdir = /var/log/puppetlabs/puppetserver
rundir = /var/run/puppetlabs/puppetserver
pidfile = /var/run/puppetlabs/puppetserver/puppetserver.pid
codedir = /etc/puppetlabs/code
dns_alt_names = puppetmaster.dev,server
[main]
certname = puppetmaster.dev
server = puppetmaster.dev
environment = production
runinterval = 1h
EOF
#Installing MySQL module 
#cd /etc/puppetlabs/code/environments/production
#rm -rf modules/*
#puppet module install --modulepath modules puppetlabs-mysql

# Add tcp PORT 8140 to firewall
echo "Allow 8140 port"
systemctl start firewalld
firewall-cmd --zone=public --add-port=8140/tcp --permanent
firewall-cmd --reload

systemctl start puppetserver
systemctl enable puppetserver

echo "Puppet installed!"