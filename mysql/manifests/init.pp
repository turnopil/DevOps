# mysql
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include mysql
class mysql {
  include mysql::install
  include mysql::configure
  include mysql::service
  include mysql::rootpass
}
