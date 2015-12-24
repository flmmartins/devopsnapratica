exec { "apt-update":
  command => "/usr/bin/apt-get update",
}

package { ["mysql-client", "tomcat7"]:
  ensure  => installed,
  require => Exec["apt-update"],
}

file { "/var/lib/tomcat7/conf/.keystore":
  owner   => root,
  group   => tomcat7,
  mode    => 0640,
  source  => "/vagrant/manifests/.keystore",
  require => Package["tomcat7"],
  notify  => Service["tomcat7"],
}

file { "/var/lib/tomcat7/conf/server.xml":
  owner   => root,
  group   => tomcat7,
  mode    => 0644,
  source  => "/vagrant/manifests/server.xml",
  require => Package["tomcat7"],
  notify  => Service["tomcat7"],
}

file { "/etc/default/tomcat7":
  owner   => root,
  group   => tomcat7,
  mode    => 0644,
  source  => "/vagrant/manifests/tomcat7",
  require => Package["tomcat7"],
  notify  => Service["tomcat7"],
}

service {"tomcat7":
  ensure     => running,
  enable     => true,
  hasstatus  => true,
  hasrestart => true,
  require => Package["tomcat7"],
}
