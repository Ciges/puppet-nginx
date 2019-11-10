class { 'nginx':
  log_format => {
    proxy_log => '[$time_local] $remote_addr - "$request" $status - $request_time msec',
    upstream_log =>  '[$time_local] $remote_addr - $server_name  to: $upstream_addr: $request - upstream_response_time $upstream_response_time msec $msec request_time $request_time msec',
  }
}

nginx::resource::server { '_':
    ensure => present, 
    listen_port => 80,
    listen_options => 'default_server',
}

