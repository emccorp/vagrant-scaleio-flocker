#!/bin/bash
# Copyright 2015 EMC Corporation

# Flocker ports need to be open
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --add-icmp-block=echo-request 
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -j ACCEPT
firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -j ACCEPT
# Docker port
firewall-cmd --permanent --zone=public --add-port=4243/tcp
# ScaleIO ports needs to be open
firewall-cmd --permanent --zone=public --add-port=6611/tcp
firewall-cmd --permanent --zone=public --add-port=9011/tcp
firewall-cmd --permanent --zone=public --add-port=7072/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=22/tcp
firewall-cmd --reload

# Prepare Flocker (flocker creates this as well I think)
mkdir /etc/flocker
chmod 0700 /etc/flocker

# Get 1.0.1 tarball
mkdir /opts/flocker
cd /opt/flocker
wget https://github.com/ClusterHQ/flocker/archive/1.0.1pre1.tar.gz
tar -zxvf 1.0.1pre1.tar.gz
cd flocker-1.0.1pre1/

# Installs Flocker 
yum -yy install openssl openssl-devel libffi-devel python-devel gcc python-virtualenv
cd /opt/flocker/flocker-1.0.1pre1/
virtualenv --python=/usr/bin/python2.7 flocker-tutorial
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/pip install --upgrade pip
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/pip install --upgrade  eliot
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/pip install --upgrade  machinist
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/pip install --upgrade pyyaml
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/pip install bitmath
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/pip install service_identity
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/python setup.py install

# Constants for where code lives
SIO_PLUGIN="https://github.com/emccorp/scaleio-flocker-driver"
PLUGIN_SRC_DIR="/opt/flocker/scaleio-flocker-driver"

# Clone in ScaleIO Plugin
git clone $SIO_PLUGIN $PLUGIN_SRC_DIR

# Install ScaleIO Driver
cd /opt/flocker/scaleio-flocker-driver
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/python setup.py install

# Add mdm (gateway) node to /etc/hosts
echo "192.168.50.12  mdm1.scaleio.local mdm1" >> /etc/hosts

# Configure Agent YML
cp /etc/flocker/example_sio_agent.yml /etc/flocker/agent.yml
sed -i -e \'s/^hostname:*/hostname: tb.scaleio.local/g\' /etc/flocker/agent.yml
sed -i -e \'s/^mdm:*/mdm: mdm1.scaleio.local/g\' /etc/flocker/agent.yml

# Create certs
cd /etc/flocker/
if [ "$HOSTNAME" = tb.scaleio.local ]; then
    printf '%s\n' "on the tb host"
    flocker-ca initialize mycluster
    flocker-ca create-control-certificate tb.scaleio.local
    cp control-tb.scaleio.local.crt /etc/flocker/control-service.crt
    cp control-tb.scaleio.local.key /etc/flocker/control-service.key
    cp cluster.crt /etc/flocker/cluster.crt
    chmod 0600 /etc/flocker/control-service.key

    # We have three nodes in the cluster.
    flocker-ca create-node-certificate
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.crt' | xargs cp -t /etc/flocker/node1.crt
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.key' | xargs cp -t /etc/flocker/node1.key
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.crt' | xargs rm
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.key' | xargs rm


    flocker-ca create-node-certificate
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.crt' | xargs cp -t /etc/flocker/node2.crt
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.key' | xargs cp -t /etc/flocker/node2.key
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.crt' | xargs rm
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.key' | xargs rm


    flocker-ca create-node-certificate
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.crt' | xargs cp -t /etc/flocker/node3.crt
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.key' | xargs cp -t /etc/flocker/node3.key
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.crt' | xargs rm
    ls -1 . | egrep '[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?-[A-Za-z0-9]*?.key' | xargs rm
fi

# Create User and API certs
# Create an API certificate for the plugin
flocker-ca create-api-certificate plugin

# Create a general purpose user api cert
flocker-ca create-api-certificate vagrantuser

# Docker needs to reload iptables after this.
service docker restart

#Install flocker-docker-plugin
yum -y install gcc
yum install -y python-pip build-essential
/opt/flocker/flocker-1.0.1pre1/flocker-tutorial/bin/pip install git+https://github.com/clusterhq/flocker-docker-plugin.git

systemctl stop docker
rm -Rf /var/lib/docker

echo 'Performing 10MB download of Docker experimental build'
yum install -y wget
wget -nv https://github.com/emccode/dogged/releases/download/docker_1.7.0_exp/docker-1.7.0 -O /bin/docker
chmod +x /bin/docker

sed -i -e \'s/^other_args=/#OPTIONS=-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock/g\' /etc/sysconfig/docker
sed -i -e \'s/^OPTIONS=/#OPTIONS=-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock/g\' /etc/sysconfig/docker

systemctl start docker

# Docker Plugin Service
if [ "$HOSTNAME" = tb.scaleio.local ]; then
    echo '[Unit]
    Description=flocker-plugin - flocker-docker-plugin job file
    
    [Service]
    Environment=FLOCKER_CONTROL_SERVICE_BASE_URL=tb.scaleio.local
    Environment=MY_NETWORK_IDENTITY=tb.scaleio.local
    ExecStart=/usr/local/bin/flocker-docker-plugin
    
    [Install]
    WantedBy=multi-user.target' >> /etc/systemd/system/flocker-docker-plugin.service
fi

if [ "$HOSTNAME" = mdm1.scaleio.local ]; then
    echo '[Unit]
    Description=flocker-plugin - flocker-docker-plugin job file
    
    [Service]
    Environment=FLOCKER_CONTROL_SERVICE_BASE_URL=tb.scaleio.local
    Environment=MY_NETWORK_IDENTITY=mdm1.scaleio.local
    ExecStart=/usr/local/bin/flocker-docker-plugin
    
    [Install]
    WantedBy=multi-user.target' >> /etc/systemd/system/flocker-docker-plugin.service
fi

if [ "$HOSTNAME" = mdm2.scaleio.local ]; then
    echo '[Unit]
    Description=flocker-plugin - flocker-docker-plugin job file
    
    [Service]
    Environment=FLOCKER_CONTROL_SERVICE_BASE_URL=tb.scaleio.local
    Environment=MY_NETWORK_IDENTITY=mdm2.scaleio.local
    ExecStart=/usr/local/bin/flocker-docker-plugin
    
    [Install]
    WantedBy=multi-user.target' >> /etc/systemd/system/flocker-docker-plugin.service
fi

# Scp node.key's to nodes
# Start flocker services
# Start the flocker-docker-plugin

# Add insecure private key for access
mkdir /root/.ssh
touch /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" > /root/.ssh/authorized_keys
