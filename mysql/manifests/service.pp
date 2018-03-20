# mysql::service
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include mysql::service
class mysql::service {
  $conf_name = $facts['os']['family'] ? {
    'RedHat' => 'mysql-redhat.cnf.erb',
}
service { 'mysql':
  ensure     => running,
  name       => 'mysqld',
  enable     => true,
  hasrestart => true,
  hasstatus  => true,
  require    => Package['mysql-community-server'],
  subscribe  => File[$conf_name]
}
}
