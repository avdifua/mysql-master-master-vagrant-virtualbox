# Master-Master MySQL Database Replication
Simple scripts for deploying mysql master-master. 
I use Ubuntu 18.04.

_fulldb08-10-2020_13-32.sql_ - data base with random data.

Assume you already have installed vagrant and virtualbox.

The next step install `vagrant-vbguest` - its need for sharing folder between your host and virtual machines. 

`sudo vagrant plugin install vagrant-vbguest`

`vagrant plugin list` - check if plugin installed.

`vagrant up` - create virtual machines

After creating machines you have to login in first master and run `master_setup.sh`. 

`vagrant ssh master1`

`chmod +x /vagrant/master_setup.sh` 

`bash /vagrant/master_setup.sh`

In the end, you have two virtual machines with installed Master-Master MySQL Database Replication.
