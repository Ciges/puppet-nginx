# NGINX module for Puppet

This **module manages NGINX configuration**. It is a fork from James Fryman <james@frymanet.com> version at Vox Pupuli (you can see original one [here](https://github.com/voxpupuli/puppet-nginx)).

This fork is for showing a demo of the following cases:
* Create a proxy to redirect requests for https://domain.com to 10.10.10.10 and redirect requests for https://domain.com/resource2 to 20.20.20.20
* Create a forward proxy to log HTTP requests going from the internal network to the Internet including: request protocol, remote IP and time take to serve the request
* Implement a proxy health check


## INSTALLING OR UPGRADING

The instructions shown here apply to an installation in agent-master architecture, in which a master node controls configuration.

To install this module download the [zip bundle](https://github.com/Ciges/puppet-nginx/archive/master.zip) on puppet master and run the following commands:

```bash
unzip puppet-nginx-master.zip
tar -czvf puppet-nginx-master.tar.gz puppet-nginx-master
rm -Rf puppet-nginx-master
puppet module install puppet-nginx-master.tar.gz
```

### Requirements

* Puppet 4.6.1 or later.  Puppet 3 was supported up until release 0.6.0.

### Additional Documentation

* [Original doc from James Fryman nginx module](http:./README_voxpopuli.md)
* [A Quickstart Guide to the NGINX Puppet Module](http:./docs/quickstart.md)

## CONFIGURATION DEMOS

For the demos we are going to consider two environments: production and test. So first we will create the environment *'production'* on master node

```
mkdir -p /etc/puppet/code/environments/production/{modules,manifests}
```



### 
