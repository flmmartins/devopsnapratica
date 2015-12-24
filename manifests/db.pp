exec { "apt-update":
  command => "/usr/bin/apt-get update"
}

package { "mysql-server":
  ensure  => installed,
  require => Exec["apt-update"],
}

file { "/etc/mysql/conf.d/allow_external.cnf": 
  owner   => mysql,
  group   => mysql,
  mode    => 0664,
  content => "[mysqld]\n bind-address = 0.0.0.0",
  require => Package["mysql-server"],
}
