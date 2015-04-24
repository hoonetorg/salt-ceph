#!/bin/sh
TIMESTAMP=$(date +%s)
SALTMASTER=10.8.8.137
apt-get install -t wheezy python-requests salt-minion
echo -n `hostname -s` > /etc/salt/minion_id
echo "$SALTMASTER	salt" >> /etc/hosts
mv /etc/salt/pki /etc/salt/.pki.$TIMESTAMP &&
  echo "backed up minion pki to $TIMESTAMP"
service salt-minion stop
#salt-call state.highstate
