# NGINX module for Puppet

This **module manages NGINX configuration**. It is a fork from James Fryman <james@frymanet.com> version at Vox Pupuli (you can see the original one [here](https://github.com/voxpupuli/puppet-nginx)).

This fork is for showing a demo of the following cases:
* A virtual host on port 80, making it the default
* A proxy to redirect requests for https://domain.com to 10.10.10.10 and redirect requests for https://domain.com/resource2 to 20.20.20.20
* A forward proxy to log HTTP requests going from the internal network to the Internet including request protocol, remote IP and time take to serve the request
* A load balancer with a proxy health check


All the manifest files used are under *[examples/production/](https://github.com/Ciges/puppet-nginx/blob/master/examples/production/)* and *[examples/test/](https://github.com/Ciges/puppet-nginx/blob/master/examples/test/)* directories, for two proposed environnements: production and test.



## INSTALLING OR UPGRADING

The instructions shown here apply to an installation in **agent-master architecture**, in which a master node controls configuration.

To install this module download the [zip bundle](https://github.com/Ciges/puppet-nginx/archive/master.zip) on puppet master and run the following commands:

```bash
unzip puppet-nginx-master.zip
tar -czvf puppet-nginx-master.tar.gz puppet-nginx-master
rm -Rf puppet-nginx-master
puppet module install puppet-nginx-master.tar.gz
```

*(In Debian 10 default puppet config dir is /etc/puppet/ so this module will be installed inder /etc/puppet/code/modules/nginx/)*

### Requirements

* Puppet 4.6.1 or later.  Puppet 3 was supported up until release 0.6.0.

### Additional Documentation

* [Original doc from James Fryman Nginx module](https://github.com/Ciges/puppet-nginx/blob/master/README_voxpopuli.md)
* [A Quickstart Guide to the NGINX Puppet Module](https://github.com/Ciges/puppet-nginx/blob/master/docs/quickstart.md)

## CONFIGURATION DEMOS

For the demos we are going to consider two environments: production and test. So first we will create both on master node

```bash
mkdir -p /etc/puppet/code/environments/production/{modules,manifests}
mkdir -p /etc/puppet/code/environments/test/{modules,manifests}
```

*(In Debian 10 default puppet environments dir is /etc/puppet/code/environments, verify puppet.conf configuration file in your installation)*

In the next sections Manifests files for the different configurations will be shown

### Virtual host on port 80, host by default

```puppet
class { 'nginx': }

nginx::resource::server { '_':
    ensure => present, 
    listen_port => 80,
    listen_options => 'default_server',
}
```

You can find this manifest in file [*examples/production/manifests/_.pp*](https://github.com/Ciges/puppet-nginx/blob/master/examples/production/manifests/_.pp), so you can copy in the production environment at puppet master node with

```bash
cd /etc/puppet/code/environments/production/manifests/
cp /etc/puppet/code/modules/nginx/examples/production/manifests/_.pp .
```

Once in the node machine, you could reload the config with

````
puppet agent --test
````

and test it pointing the browser to an URL pointing to the IP of the node server.


### Proxy to redirect requests for https://domain.com to 10.10.10.10 and redirect requests for https://domain.com/resource2 to 20.20.20.20

All requests to https://domain.com will be redirected also encrypted with SSL, using "fake" self-signed certificate *"snakeoil"* present in OpenSSL package by default.

````puppet
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
````

The manifest is in file [*examples/production/manifests/reverse_proxy_domaincom.pp*](https://github.com/Ciges/puppet-nginx/blob/master/examples/production/manifests/reverse_proxy_domaincom.pp), so you can copy it in the production environment as shown before.


### Forward proxy to log HTTP requests going from the internal network to the Internet

Here we will make the following:
* Add a custom log format to the default configuration (file *[_.pp](https://github.com/Ciges/puppet-nginx/blob/master/examples/production/manifests/_.pp)* shown before)

```puppet
class { 'nginx':
  log_format => {
    proxy_log => '[$time_local] $remote_addr - "$request" $status - $request_time sec',
  }
}

nginx::resource::server { '_':
    ensure => present, 
    listen_port => 80,
    listen_options => 'default_server',
}
```

* Add the manifest for the new forward proxy that will run at port 8080

```puppet
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
```

In this case the manifest is available at [*examples/production/manifests/forward_proxy.pp*](https://github.com/Ciges/puppet-nginx/blob/master/examples/production/manifests/forward_proxy.pp)

To test it, we can tun the chrome navigator using the address of the agent node with the server deployed (*"debianvm.ciges.local*" in the example) as option with

````bash
google-chrome --proxy-server=debianvm.ciges.local:8080
````

And see the proxy running viewing the log at */var/log/nginx/http_proxy.access.log* on agent node


### Load balancer with a proxy health check

In this case we are going to:
* Add a custom log in the default configuration
* Configure a load balancer for the URL www.ciges.net who will send request in a round-robin way to three Nginx instances, two of then in port 8090 in the local network and the third one in VPS located in Internet
* Configure a passive health check, for not sending a new request to a server if it failed three times in the last minute


With the new custom log format *"upstream_log"* the default configuration (file *[_.pp](https://github.com/Ciges/puppet-nginx/blob/master/examples/production/manifests/_.pp)* will be:

```puppet
class { 'nginx':
  log_format => {
    proxy_log => '[$time_local] $remote_addr - "$request" $status - $request_time sec',
    upstream_log =>  '[$time_local] $remote_addr - $server_name  to: $upstream_addr: $request - upstream_response_time $upstream_response_time msec $msec request_time $request_time sec',
  }
}

nginx::resource::server { '_':
    ensure => present, 
    listen_port => 80,
    listen_options => 'default_server',
}
```

And the new manifest file to deploy an Nginx load balancer as told will be:

```puppet
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
```

The manifest is available at [*examples/production/manifests/load_balancer_cigesnet.pp*](https://github.com/Ciges/puppet-nginx/blob/master/examples/production/manifests/load_balancer_cigesnet.pp)

The servers on 192.168.56.10 and 192.168.56.11 are both puppet nodes on my local network, the first one in *"production"* environment and the second one in *"test"* with instances configured to listen on 8090 port. The third IP address is from a VPS on Internet hosting www.ciges.net.

The directive *ip_hash*, commented for testing the health check, allows to send the request from the same client to the same destination server, which allows the use of sessions, needed in most real scenarios.

Once running we could see how the load balancer works reading the contents of the log */var/log/nginx/cigesnet_lb.access.log*.

