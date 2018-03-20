class profiles::mysqlserver::users {
include mysql
}
mysql::db { 'bugtrckr':
  database => 'bugtrckr',
  charset  => 'utf8',
  collate  => 'utf8_unicode_ci',
}
mysql::db { 'test1':
  database => 'test1',
  charset  => 'utf8',
  collate  => 'utf8_unicode_ci',
}
mysql::users { 'tomcat': 
  table     => 'bugtrckr', # GRANT ALL ON ${table}.*
  user      => 'tomcat',
  user_pass => 'la_3araZa',
  host      => '%',
  grant     => 'ALL',
}




