class profiles::mysqlserver::master (

  $datadir                = "/var/lib/mysql", # can also be defined under override option
  $port                   = "3306", # can also be defined under override option
  $bind_address           = "0.0.0.0",  # can also be defined under override option
  $is_master              = false, # True if the node is master
  $replica_user           = "replication", # For master, what is the replication account
  $replica_password       = "replication", # Replication User password
  $replica_password_hash  = '*D36660B5249B066D7AC5A1A14CECB71D36944CBC', # the same replication account password hashed
  $is_slave               = true,  # True if the node is slave
  $master_ip              = "172.10.20.10",     # The IP Address of the master in case this is a slave
  $master_port            = "3306", # The port where the master is listening to

)
{
include mysql



if $is_master {
    mysql::users { '${replica_user}': 
      table     => '*', # GRANT ALL ON ${table}.*
      user      => $replica_user,
      user_pass => 'la_3araZa',
      host      => '%',
      grant     => 'ALL',
    }
  }
}


