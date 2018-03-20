# mysql::database
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include mysql::database
class mysql::database (
  $temp_pass   = "$(grep 'temporary password' /var/log/mysqld.log|cut -d \":\" -f 4|cut -d ' ' -f 2)",
  $root_pass   = 'a8+?treAvpDa',
  $tomcat_pass = 'la_3araZa',
  $pass_cmd    = "mysqladmin -u root --password=${temp_pass} password '${root_pass}'",
)
{

Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
}
exec { 'install_pass':
  command   => $pass_cmd,
  logoutput => true,
  unless    => "mysqladmin -u root -p'${root_pass}' status > /dev/null",
}
exec { 'mysql_database_create':
  command => "mysql -u root -p'${root_pass}' -e \"CREATE DATABASE bugtrckr;\"",
  unless  => "mysql -u root -p'${root_pass}' -e \"SHOW DATABASES;\" | grep bugtrckr",
  require => Package['mysql-community-server'],
}
exec { 'mysql_user_create':
  command => "mysql -u root -p'${root_pass}' -e \"GRANT ALL ON bugtrckr.* TO \'tomcat\'@\'%\' IDENTIFIED BY \'${tomcat_pass}\';FLUSH PRIVILEGES;\"",
  unless  => "mysql -u root -p'${root_pass}' -e \"SELECT * FROM mysql.user;\" | grep tomcat",
  require => [Package['mysql-community-server'], Exec['mysql_database_create']],
}
}

#mysql -u root -pa8+?treAvpDa -e "GRANT REPLICATION SLAVE ON *.* TO 'replication'@'%' IDENTIFIED BY 'replication';"
