#!/bin/sh
TIMESTAMP=$(date +%s)
SALTMASTER=10.8.8.137
apt-get install -t wheezy python-requests salt-minion
mkdir -p /etc/salt/minion.d/
echo -e "ipv6: True\nmaster: deploy.infralab.arkena.net" > /etc/salt/minion.d/master.conf
echo -n `hostname -f` > /etc/salt/minion_id
echo "$SALTMASTER	salt" >> /etc/hosts
mv /etc/salt/pki /etc/salt/.pki.$TIMESTAMP &&
  echo "backed up minion pki to $TIMESTAMP"
service salt-minion stop
#salt-call state.highstate
