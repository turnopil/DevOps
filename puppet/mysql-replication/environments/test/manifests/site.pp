node 'mysqlmaster.local' {
include mysqlprofile::mysqlmaster
include stdlib
}
class mysqlprofile::mysqlmaster {
  notice("Loading mysqlmaster")

  class { '::mysql::server':
    restart          => true,
    root_password    => 'changeme',
    override_options => {
      'mysqld' => {
        'bind_address'                   => '0.0.0.0',
        'server-id'                      => '1',
        'binlog-format'                  => 'mixed',
        'log-bin'                        => 'mysql-bin',
        'datadir'                        => '/var/lib/mysql',
        'innodb_flush_log_at_trx_commit' => '1',
        'sync_binlog'                    => '1',
        'binlog-do-db'                   => ['demo'],
        'log-error'                      => "/var/log/mysqld.log",
      },
      'mysqld_safe' => {
        'log-error'                      => "/var/log/mysqld.log",
      },
    }
  }

  mysql_user { 'slave_user@%':
    ensure        => 'present',
    password_hash => mysql_password('changeme'),
  }

  mysql_grant { 'slave_user@%/*.*':
    ensure     => 'present',
    privileges => ['REPLICATION SLAVE'],
    table      => '*.*',
    user       => 'slave_user@%',
  }

  mysql::db { 'demo':
    ensure   => 'present',
    user     => 'demo',
    password => 'changeme',
    host     => '%',
    grant    => ['all'],
  }

}
node 'mysqlslave.local' {
include mysqlprofile::mysqlslave
include stdlib
}
class mysqlprofile::mysqlslave {
  notice("Loading mysqlslave")

  class { '::mysql::server':
    restart          => true,
    root_password    => 'changeme',
    override_options => {
      'mysqld' => {
        'bind_address' => '0.0.0.0',
        'server-id'         => '2',
        'binlog-format'     => 'mixed',
        'log-bin'           => 'mysql-bin',
        'relay-log'         => 'mysql-relay-bin',
        'log-slave-updates' => '1',
        'read-only'         => '1',
        'replicate-do-db'   => ['demo'],
        'log-error'         => "/var/log/mysqld.log",
      },
      'mysqld_safe' => {
        'log-error'         => "/var/log/mysqld.log",
      },
    }
  }

  mysql::db { 'demo':
    ensure   => 'present',
    user     => 'demo',
    password => 'changeme',
    host     => '%',
    grant    => ['all'],
  }
}