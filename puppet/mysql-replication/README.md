## Mysql Master-Slave replication with Puppet
To run the demo in vagrant, run

	vagrant up  # provision the three nodes with vagrant

to configure your `mysqlserver` and `mysqlslave` nodes, then follow the steps below
to get replication running between them.

#### On Puppet Master
Run puppet cert sign command to sign a request.

	vagrant ssh puppetmaster

	sudo /opt/puppetlabs/bin/puppet cert list
    sudo /opt/puppetlabs/bin/puppet cert sign --all

The puppet master can now communicate to the client machine and control the node.

Then install modules

	cd /etc/puppetlabs/code/environments/production
	rm -rf modules
	/opt/puppetlabs/bin/puppet module install --modulepath modules puppetlabs-mysql

Now replace `params.pp` in `modules/mysql/manifests` 

#### On Mysql Master && Slave
Run the following command on the client machine to test it.

	vagrant ssh mysqlmaster
	vagrant ssh mysqlslave

	sudo /opt/puppetlabs/bin/puppet agent --test

#### On Mysql Master
# Import settings from application to MySQL database

	mysql -u root -p"$DATABASE_PASS"
	mysql> USE bugtrckr;
	mysql> SHOW TABLES;

	mysql -u root -p"$DATABASE_PASS" bugtrckr < data-dump.sql

#### On Mysql Slave
Check replication status

	mysql -u root -p"$DATABASE_PASS"
	SHOW SLAVE STATUS\G

	mysql> USE bugtrckr;
	mysql> SHOW TABLES;