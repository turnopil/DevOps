include profiles::mysqlserver
include stdlib

class profiles::mysqlserver (
  $root_password          = "a8+?treAvpDa", # set password as Myr00t
  $override_options       = {},    # define server options in this hash
  $datadir                = "/var/lib/mysql", # can also be defined under override option
  $port                   = "3306", # can also be defined under override option
  $pid_file               = "/var/run/mysqld/mysqld.pid", # can also be defined under override option
  $socket                 = "/var/lib/mysql/mysql.sock", # can also be defined under override option
  $bind_address           = "0.0.0.0",  # can also be defined under override option
  $log_error              = "/var/log/mysqld.log",  # required for proper MySQL installation
# $explicit_defaults_for_timestamp = 1, # To avoid "TIMESTAMP with implicit DEFAULT value is deprecated." error on 5.6
  $dbs                    = {},    # Hash of Array for mysql::db
  $community_release      = true, # Set to true to use community edition
  $community_major_v      = '5',   # If using community what is the major version
  $community_minor_v      = '7',   # If using community what is the minor version
  $is_master              = true, # True if the node is master
  $replica_user           = "replication", # For master, what is the replication account
  $replica_password       = "replication", # Replication User password
  $replica_password_hash  = '*D36660B5249B066D7AC5A1A14CECB71D36944CBC', # the same replication account password hashed
  $slaves_ips             = [],     # What are the potentials slave for this master
  $is_slave               = false,  # True if the node is slave
  $master_ip              = "172.10.20.10",     # The IP Address of the master in case this is a slave
  $master_port            = "3306", # The port where the master is listening to

)
{
  
  ### Check Additional defined option and merge to have full defined options
  $additional_override_options = {
    'mysqld' => {
       'datadir'      => "${datadir}",
       'port'         => "${port}",
       'pid-file'     => "${pid_file}",
       'socket'       => "${socket}",
       'bind-address' => "${bind_address}",
       'log-error'    => "${log_error}",
      # 'explicit-defaults-for-timestamp' => "{explicit_defaults_for_timestamp}",
    },
    'mysqld_safe' => {
       'log-error'    => "${log_error}",
    }
  }

  $full_override_options = deep_merge($additional_override_options, $override_options)

  ### Install the requested Mysql Release
  if $community_release == false {
    class { '::mysql::server':
      root_password           => $root_password,
      override_options        => $full_override_options,
      restart                 => true, #service should be restarted when things change
    }
  }
  else {
    # $url_repo = "http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm"
  	  $url_repo = "http://dev.mysql.com/get/mysql${community_major_v}${community_minor_v}-community-release-el${::facts['os']['release']['major']}-${community_minor_v}.noarch.rpm"
      package { 'mysql-community-repo':
      name      => "mysql-community-server-${community_major_v}.${community_minor_v}.16-1.el${community_minor_v}.x86_64",
    # name      => "mysql${community_major_v}${community_minor_v}-community-release",
      ensure    => installed,
      provider  => rpm,
      source    => $url_repo,
    }
    
    class { '::mysql::server':
      root_password           => $root_password,
      override_options        => $full_override_options,
      package_name            => 'mysql-community-server',
      package_ensure          => 'present',
      restart                 => true, #service should be restarted when things change
      require                 => Package['mysql-community-repo'],
    }
  }

  ### With Create Resource Converts a hash into a set of resources and create dbs
  create_resources(mysql::db, $dbs)

  ### Check if this system was marked as master and set appropriate params and users
  if $is_master {
  
    if $full_override_options['mysqld']['bind-address'] == "127.0.0.1" {
        fail("This cant be a master and listening only to localhost, you must change the bind_address variable to a suitable one")
    }
         
      mysql_user { "${replica_user}@%":
        ensure                   => 'present',
        max_connections_per_hour => '0',
        max_queries_per_hour     => '0',
        max_updates_per_hour     => '0',
        max_user_connections     => '0',
        password_hash            => $replica_password_hash,
      }
    
      mysql_grant { "${replica_user}@%/*.*":
        ensure                 => 'present',
        options                => ['GRANT'],
        privileges             => ['REPLICATION SLAVE'],
        table                  => '*.*',
        user                   => "${replica_user}@%",
        require                => Mysql_user["${replica_user}@%"],
      }

  }
  
  ### Check if this system was marked as slave and set appropriate params and commands
  if $is_slave {
    validate_ip_address($master_ip)  # IP Address must be set to identify the master
    $cmd_change_master = join(["CHANGE MASTER TO MASTER_HOST","\'${master_ip}\',MASTER_PORT","${master_port},MASTER_USER","\'${replica_user}\',MASTER_PASSWORD","\'${replica_password}\';"], "=") 
    $cmd_start_slave   = "START SLAVE;"
    exec { 'set_master_params':
      command => "mysql --defaults-extra-file=/root/.my.cnf --execute=\"${cmd_change_master}${cmd_start_slave}\"",
      require => Class['::mysql::server'],
      path    => ["/usr/local/sbin","/usr/local/bin","/sbin","/bin","/usr/sbin","/usr/bin","/opt/puppetlabs/bin","/root/bin"],
      unless  => "grep ${master_ip} $datadir/master.info && grep ${master_port} $datadir/master.info && grep -w ${replica_user} $datadir/master.info && grep -w ${replica_password} $datadir/master.info",
    }
  }  
}
