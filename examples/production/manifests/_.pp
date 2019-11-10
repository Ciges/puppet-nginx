class { 'nginx':
  log_format => {
    proxy_log => '[$time_local] $remote_addr "$request" $status - $request_time s'
  }
}

nginx::resource::server { '_':
    ensure => present, 
    listen_port => 80,
    listen_options => 'default_server',
}

