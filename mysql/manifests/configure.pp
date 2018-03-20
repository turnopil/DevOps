# mysql::configure
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include mysql::configure
class mysql::configure (
  $bind = '0.0.0.0',
)
{

  $conf_name = $facts['os']['family'] ? {
    'RedHat' => 'mysql-redhat.cnf.erb',
}
  $path_file = $facts['os']['family'] ? {
    'RedHat' => '/etc/my.cnf',
}
file { $conf_name:
  ensure  => present,
  path    => $path_file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => template("mysql/${conf_name}"),
  notify  => Service['mysql']
}
file { '.my.cnf':
  ensure => present,
  path   => '/root/.my.cnf',
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => 'puppet:///modules/mysql/root_pass.cnf',
}
}