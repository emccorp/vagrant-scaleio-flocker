#!/bin/bash

# SystemCTL complains about single quotes and won't start
sed -i "s/OPTIONS='--selinux-enabled'/OPTIONS=--selinux-enabled/g" /etc/sysconfig/docker

# enable root login, key authentication will still need to be setup
sed -i 's/PermitRootLogin .*/PermitRootLogin yes/g' /etc/ssh/sshd_config
service sshd restart

# Add EMC certs
yum install ca-certificates
update-ca-trust enable
cp /vagrant/certs/EMC*.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

yum install -y kernel-devel kernel
yum install -y epel-release
sync


