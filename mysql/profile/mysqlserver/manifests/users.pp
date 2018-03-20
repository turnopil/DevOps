class profile::mysqlserver::users {
    include mysql
}
  mysql::db { 'tomcat':
  database => 'bugtrckr',
  table    => 'tomcat',
  user     => 'tomcat',
 user_pass => 'la_3araZa',
  host     => '%',
  grant    => 'ALL',
	 }
