# mysql::rootpass
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include mysql::rootpass
class mysql::rootpass (
  $temp_pass = "$(grep 'temporary password' /var/log/mysqld.log|cut -d \":\" -f 4|cut -d ' ' -f 2)",
  $root_pass = 'a8+?treAvpDa',
  $pass_cmd  = "mysqladmin -u root --password=${temp_pass} password '${root_pass}'",
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

}
