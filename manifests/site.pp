class ghost {
  $app_path = '/vagrant'
  $ghost = 'ghost-0.3.3'
  $home_path = '/home/vagrant'
  $nodejs_version = 'v0.10.21'
  $path = '/usr/local/bin:/usr/bin/:bin/'
  $user = 'vagrant'

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
  }

  class { 'nodejs':
    version => "$nodejs_version",
    make_install => false,
    require => Exec['apt-get update'],
  }

  package { ["vim",
             "curl",
             "git-core",
             "bash",
             "unzip"]:
    ensure => present,
    require => Exec["apt-get update"],
  }

  exec { "download_ghost":
    command => "curl -L -O https://ghost.org/zip/${ghost}.zip && unzip ${ghost}.zip -d ${ghost} && rm ${ghost}.zip",
    cwd => "$app_path",
    user => "${user}",
    path    => "$path",
    require => [ Package["unzip"], Package["curl"] ],
    logoutput => true,
    creates => "${app_path}/${ghost}",
  }

  exec { "install_npm":
    command => "npm install --production",
    cwd => "${app_path}/${ghost}",
    path => "$path",
    logoutput => true,
    require => Exec['download_ghost'],
  }

  user { "$user":
    comment => 'ghost user',
    home => "$home_path",
    managehome => true,
    before => File["$app_path"],
  }

  file { "$app_path":
    ensure => 'directory',
    owner => $user,
    mode => 755,
    before => Exec['download_ghost'],
  }

  supervisor::service { 'ghost':
    ensure => present,
    command => "/usr/local/bin/node $app_path/$ghost/index.js",
    directory => "$app_path/$ghost",
    environment => "NODE_ENV='production'",
    user => "$user",
    require => Exec['install_npm'],
  }

  class { 'supervisor':
    conf_dir => '/etc/supervisor/conf.d',
    conf_ext => '.conf',
    before => Exec['install_npm'],
  }
}

include ghost
