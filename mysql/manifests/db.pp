# mysql::db
#
# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   mysql::db { 'namevar': }
define mysql::db(
  String $database,
  String $table,
  String $user,
  String $user_pass,
  String $host,
  String $grant,
)
{
include mysql
$r_pass = $mysql::database::root_pass
Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
}
exec { 'mysql_${database}_create':
  command => "mysql -u root -p'${r_pass}' -e \"CREATE DATABASE ${database};\"",
  unless  => "mysql -u root -p'${r_pass}' -e \"SHOW DATABASES;\" | grep ${database}",
  require => [Package['mysql-community-server'], Exec['install_pass']],
}
exec { 'mysql_${user}_create':
  command => "mysql -u root -p'${r_pass}' -e \"GRANT ${grant} ON ${table}.* TO \'${user}\'@\'${host}\' IDENTIFIED BY \'${pass}\';FLUSH PRIVILEGES;\"",
  unless  => "mysql -u root -p'${r_pass}' -e \"SELECT * FROM mysql.user;\" | grep ${user}",
  require => [Package['mysql-community-server'], Exec['mysql_${database}_create']],
}
}
