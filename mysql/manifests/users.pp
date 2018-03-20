# mysql::users
#
# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   mysql::users { 'namevar': }
define mysql::users(
	String $table,
  String $user,
  String $user_pass,
  String $host,
  String $grant,
)
{
include mysql
$r_pass = $mysql::rootpass::root_pass
Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
}
exec {"${user}":
  command => "mysql -u root -p'${r_pass}' -e \"GRANT ${grant} ON ${table}.* TO \'${user}\'@\'${host}\' IDENTIFIED BY \'${user_pass}\';FLUSH PRIVILEGES;\"",
  unless  => "mysql -u root -p'${r_pass}' -e \"SELECT * FROM mysql.user;\" | grep ${user}",
  require => Package['mysql-community-server'],
}
}
