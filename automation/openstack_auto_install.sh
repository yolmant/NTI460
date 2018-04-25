#!/bin/bash

# script to automate openstack install with ansible (run as root)

# **** configure CentOS; these steps could also be completed before ansible/openstack install

yum -y upgrade

# should reboot here, but will reboot at the end of the script

# install additional packages

yum -y install https://rdoproject.org/repos/openstack-ocata/rdo-release-ocata.rpm

yum -y install git ntp ntpupdate openssh-server python-devel \

sudo '@Development Tools'

# **** configure ntp to sync with a timesource

# **** configure the network -- assign IPs to mgmt server, hosts, and iSCSI and confirm ssh connectivity. Ansible will fail without ssh

# install the source and dependencies

# clone the latest release of the openstack-ansible git repo

git clone -b 15.1.19 https://git.openstack.org/openstack/openstack-ansible \
/opt/openstack-ansible

cd /opt/openstack-ansible

scripts/bootstrap-ansible.sh

# **** configure ssh keys

# not sure how we want to do this; we could import ssh keys or allow the script to make new keys

# **** prepare the target hosts (the following commands should be executed on the compute nodes -- run as root)

yum upgrade
