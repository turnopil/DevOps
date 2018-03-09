class roles::mydb  {
 
    # Install Oracle Server
    include profiles::mysqlserver
    include profiles::mysqlreplica
}
