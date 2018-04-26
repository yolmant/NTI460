#!/bin/bash

# script to automate openstack install with ansible (run as root)

# comments marked '****' need more configuration or information to complete

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

# should reboot here, but will reboot at the end of the script

# check to make sure kernel is version 3.10 or later

uname -r

# install additional software packages

yum -y install bridge-utils iputils lsof lvm2 \
ntp ntpdate openssh-server sudo tcpdump

# add kernel modules to /etc/modules to enable VLAN and bond interfaces

echo 'bonding' >> /etc/modules-load.d/openstack-ansible.conf
echo '8021q' >> /etc/modules-load.d/openstack-ansible.conf

# configure NTP in /etc/ntp.conf to sync with a time source and start the service

systemctl enable ntpd.service
systemctl start ntpd.service

# **** deploy the SSH keys created from the mgmt server

#Ansible uses SSH to connect the deployment host and target hosts.

# Copy the contents of the public key file on the deployment host to the /root/.ssh/authorized_keys file on each target host.
# Test public key authentication from the deployment host to each target host by using SSH to connect to the target host from
# the deployment host.
# If you can connect and get the shell without authenticating, it is working. SSH provides a shell without asking for a
# password.
# For more information about how to generate an SSH key pair, as well as best practices, see GitHub’s documentation about
# generating SSH keys.

# **** configure storage -- needs information on iSCSI

# pvcreate --metadatasize 2048 physical_volume_device_path
# vgcreate cinder-volumes physical_volume_device_path

# **** configure networking on the hosts -- needs network information and configuration

# the following table shows bridges that are to be configured on hosts

# Bridge name	    Best configured on	    With a static IP

#   br-mgmt	        On every node	          Always
#   br-storage	    On every storage node	  When component is deployed on bare metal
#                   On every compute node	  Always
#   br-vxlan	      On every network node	  When component is deployed on bare metal
#                   On every compute node	  Always
#   br-vlan	        On every network node	  Never
#                   On every compute node	  Never

# **** configure the deployment (run on the controller as root)

cp /opt/openstack-ansible/etc/openstack_deploy /etc/openstack_deploy

cd /etc/openstack_deploy

cp openstack_user_config.yml.example /etc/openstack_deploy/openstack_user_config.yml

# **** review the openstack_user_config.yml file and configure to our environment

# **** install additional services?
# To install additional services, the files in /etc/openstack_deploy/conf.d provide examples showing
# the correct host groups to use. To add another service, add the host group, allocate hosts to it,
# and then execute the playbooks.

# review openstack/infrastructure service roles for services
# configure service credentials

# configure credentials for each service in the /etc/openstack_deploy/*_secrets.yml files
# use the Ansible Vault feature? increases security by encrypting any files that contain credentials
# djust permissions on these files to restrict access by nonprivileged users

# chmod 400 -R </path/to/credentials>

# keystone_auth_admin_password option configures the admin tenant password for both the openstack API and dashboard access.

# use the pw-token-gen.py script to generate random values for the variables in each file that contains service credentials:

# cd /opt/openstack-ansible
# ./scripts/pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml

# regenerate existing passwords, add the --regen flag

# **** Ensure that all the files edited in the /etc/openstack_deploy directory are Ansible YAML compliant

cd /opt/openstack-ansible/playbooks
openstack-ansible setup-infrastructure.yml --syntax-check

# **** important: recheck that all indentation is correct. this is important because
# the syntax of the configuration files can be correct while not being meaningful for OpenStack-Ansible

# **** RUN THE PLAYBOOKS TO INSTALL OPENSTACK ****

# run the host setup playbook
cd /opt/openstack-ansible/playbooks
openstack-ansible setup-hosts.yml

# satisfactory completion with zero items unreachable or failed in output

# run the infrastructure setup playbook
openstack-ansible setup-infrastructure.yml

# satisfactory completion with zero items unreachable or failed in output

# verify the database cluster
ansible galera_container -m shell \
-a "mysql -h localhost -e 'show status like \"%wsrep_cluster_%\";'"

# run the openstack setup playbook
openstack-ansible setup-openstack.yml

# satisfactory completion with zero items unreachable or failed in output

# verify openstack isntallation

# determine the name of the utility container
touch utility_container.txt
lxc-ls | grep utility > utility_container.txt

# access the utility_container
lxc-attach -n < utility_container.txt

# source the admin tenant credentials
touch /root/admin_tenant_creditials.txt
source /root/openrc > /root/admin_tenant_creditials.txt

# run an openstack command
openstack user list

# verify the dashboard (horizon)

# With a web browser, access the Dashboard by using the external load balancer IP address defined by
# the external_lb_vip_address option in the /etc/openstack_deploy/openstack_user_config.yml file.
# The Dashboard uses HTTPS on port 443.

# Authenticate by using the admin user name and the password defined by the keystone_auth_admin_password
# option in the /etc/openstack_deploy/user_secrets.yml file.

echo "open-stack-ansible installation complete!"
