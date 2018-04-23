#!/bin/bash
# ansible userdata (ami-43a15f3e)
cd /tmp
wget https://s3-eu-west-1.amazonaws.com/turnopil/mysql.sh
sudo chown ubuntu:ubuntu mysql.sh
sudo chmod 755 mysql.sh 
./mysql.sh

sudo apt-add-repository ppa:ansible/ansible -y 
sudo apt-get update
sudo apt-get install ansible -y
cd /tmp
wget https://s3-eu-west-1.amazonaws.com/turnopil/playbook1.tar.gz
sudo tar zxvf playbook1.tar.gz
cd /tmp/playbook
sudo ansible-playbook main.yml --connection=local -i localhost, -e target=localhost
