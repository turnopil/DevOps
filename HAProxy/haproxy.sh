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
yum update -y --nogpgcheck > /dev/null 2>&1

# Make sure you have these installed
yum install -y make gcc perl pcre-devel zlib-devel openssl-devel > /dev/null 2>&1

# Download/Extract source
wget -O /tmp/haproxy.tgz http://www.haproxy.org/download/1.7/src/haproxy-1.7.8.tar.gz > /dev/null 2>&1
tar -zxvf /tmp/haproxy.tgz -C /tmp
cd /tmp/haproxy-*

# Compile HAProxy
# https://github.com/haproxy/haproxy/blob/master/README
make \
    TARGET=linux2628 USE_LINUX_TPROXY=1 USE_ZLIB=1 USE_REGPARM=1 USE_PCRE=1 USE_PCRE_JIT=1 \
    USE_OPENSSL=1 SSL_INC=/usr/include SSL_LIB=/usr/lib ADDLIB=-ldl \
    CFLAGS="-O2 -g -fno-strict-aliasing -DTCP_USER_TIMEOUT=18"
make install

# Check your sbin path at /usr/local/sbin, consider copying these two to it
cp haproxy /usr/local/sbin/haproxy
cp haproxy-systemd-wrapper /usr/local/sbin/haproxy-systemd-wrapper

mkdir -p /etc/haproxy
mkdir -p /var/lib/haproxy 
touch /var/lib/haproxy/stats

sudo ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy

# Add http to firewall
echo "Allow http"
# Restart Firewalld service
#systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --reload
#firewall-cmd --list-all

# File located at /etc/systemd/system/haproxy.service for CentOS 7
# Reference https://github.com/horms/haproxy/blob/master/contrib/systemd/haproxy.service.in
cat>/etc/systemd/system/haproxy.service<<EOF
[Unit]
Description=HAProxy Load Balancer
After=network.target

[Service]
ExecStartPre=/usr/local/sbin/haproxy -f /etc/haproxy/haproxy.cfg -c -q
ExecStart=/usr/local/sbin/haproxy-systemd-wrapper -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid
ExecReload=/bin/kill -USR2 $MAINPID
KillMode=mixed
Restart=always

[Install]
WantedBy=multi-user.target
EOF

useradd -r haproxy
chkconfig haproxy on