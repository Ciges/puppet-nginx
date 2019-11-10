include nginx

# Proxy for www.ciges.net
# Requests are sent to http://www.ciges.net at 164.132.103.253
nginx::resource::server { 'ciges.net':
    ensure => present,
    listen_port => 8090,
    proxy => 'http://164.132.103.253/',
} 
