# NGINX module for Puppet

This **module manages NGINX configuration**. It is a fork from James Fryman <james@frymanet.com> version at Vox Pupuli (you can see original one [here](https://github.com/voxpupuli/puppet-nginx)).

This fork is for showing a demo of the following cases:
* [Create a virtual host on port 80, and make it the default](#virtual-host-on-port-80-host-by-default)
* Create a proxy to redirect requests for https://domain.com to 10.10.10.10 and redirect requests for https://domain.com/resource2 to 20.20.20.20
* Create a forward proxy to log HTTP requests going from the internal network to the Internet including: request protocol, remote IP and time take to serve the request
* Implement a proxy health check


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

* [Original doc from James Fryman nginx module](https://github.com/Ciges/puppet-nginx/blob/master/README_voxpopuli.md)
* [A Quickstart Guide to the NGINX Puppet Module](https://github.com/Ciges/puppet-nginx/blob/master/docs/quickstart.md)

## CONFIGURATION DEMOS

For the demos we are going to consider two environments: production and test. So first we will create the environment *'production'* on master node

```bash
mkdir -p /etc/puppet/code/environments/production/{modules,manifests}
```

*(In Debian 10 default puppet environments dir is /etc/puppet/code/environments, verify puppet.conf configuration file in your installation)*

In the next sections Manifest for the different configuration will be shown

### Virtual host on port 80, host by default

*_.pp*
```puppet
class { 'nginx': }

nginx::resource::server { '_':
    ensure => present, 
    listen_port => 80,
    listen_options => 'default_server',
}
```

You can find this manifest in file [*examples/production/manifests/_.pp*](https://github.com/Ciges/puppet-nginx/blob/master/examples/production/manifests/_.pp), so you can copy in the production environnement at puppet master node with

```bash
cd /etc/puppet/code/environments/production/manifests/
cp /etc/puppet/code/modules/nginx/examples/production/manifests/_.pp .
```

Once in the node machine, you could reload the config with

````
puppet agent --test
````

### Proxy to redirect requests for https://domain.com to 10.10.10.10 and redirect requests for https://domain.com/resource2 to 20.20.20.20

All request to https://domain.com will be redirected also encrypted with SSL, using "fake" self-signed certificate *"snakeoil"* present in OpenSSL package by default.

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
* Add a custom log format to the default configuration
* Add the manifest for the new forward proxy
