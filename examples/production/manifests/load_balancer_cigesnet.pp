include nginx

nginx::resource::upstream { 'cigesnet_us':
    ensure  => present,
    members => {
        'local_vm1' => {
            server => '192.168.56.10',
            port   => 8090,
        },
        'local_vm2' => {
            server => '192.168.56.11',
            port   => 8090,
        },
        'vps' => {
            server => '164.132.103.253',
            port   => 80,
        },
    },
    member_defaults => {
        max_fails => 3,
        fail_timeout => '60s',
    },
    # Uncomment to make clients preserve destination server in consecutive requests
    #ip_hash => true,
}

nginx::resource::server { 'cigesnet_lb':
    ensure => present,
    listen_port => 9090,
    proxy => 'http://cigesnet_us',
    access_log => '/var/log/nginx/cigesnet_lb.access.log',
    format_log => upstream_log,
} 
