# mysql::install
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include mysql::install
class mysql::install (
  $community_major_v = '5',
  $community_minor_v = '7',
)

{
  $url_repo = "http://dev.mysql.com/get/mysql${community_major_v}${community_minor_v}-community-release-el${::facts['os']['release']['major']}-${community_minor_v}.noarch.rpm"
package { 'mysql-community-repo':
  ensure   => installed,
# name     => "mysql${community_major_v}${community_minor_v}-community-release",
  name     => "mysql-community-server-${community_major_v}.${community_minor_v}.16-1.el${community_minor_v}.x86_64",
  provider => rpm,
  source   => $url_repo,
}
package { 'mysql-community-server':
  ensure  => present,
  require => Package['mysql-community-repo'],
}
}
