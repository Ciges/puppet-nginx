nginx::resource::server { 'http_proxy':
    ensure => present,
    listen_port => 8080,
    resolver => [ '213.60.205.175', '8.8.8.8' ],
    proxy => 'http://$http_host$uri$is_args$args',
    proxy_set_header => [
        'Host $http_host',
    ],
    format_log => 'proxy_log',
    access_log => '/var/log/nginx/http_proxy.access.log'
}

