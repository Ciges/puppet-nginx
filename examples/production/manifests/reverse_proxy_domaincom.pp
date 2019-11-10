include nginx

# Reverse proxy for domain.com
# Request are redirected to 10.10.10.10, except under /resource2 wich are redirected to 20.20.20.20
nginx::resource::server { 'domain.com':
    ensure => present,
    listen_port => 443,
    proxy => 'https://10.10.10.10/',
    proxy_set_header => [ 
      'Host $http_host',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto https',
    ],
    ssl => true,
    ssl_cert => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key => '/etc/ssl/private/ssl-cert-snakeoil.key'
}

nginx::resource::location { '/resource2/':
    ensure => present,
    proxy => 'https://20.20.20.20/',
    proxy_set_header => [ 
      'Host $http_host',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto https',
    ],
    server => 'domain.com',
    ssl_only => true,
}

