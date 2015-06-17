#!/usr/bin/env python

import  os
import  subprocess
import  collections
import  yaml
import  salt.pillar
import  salt.utils
from    salt._compat import string_types

def __virtual__():
  return 'bootstrap'

def get_key_from(dirname):
  _pillar_ = salt.pillar.get_pillar(
    __opts__,
    __grains__,
    __opts__.get('id'),
    __opts__['environment'],
  ).compile_pillar()

  filename = '%s/%s.keyring' %(dirname, _pillar_['ceph']['cluster']['name'])
  with open(filename) as fd:
    for line in fd:
      line = line.rstrip()
      line = line.replace(' ', '')
      line = line.replace('key=', 'key ')
      if 'key ' in line:
        return line.split()[1]

def osd():
  return get_key_from('/var/lib/ceph/bootstrap-osd')

def mds():
  return get_key_from('/var/lib/ceph/bootstrap-mds')

def api():
  # this path is determined in the inkscope service api states
  # it is NOT standard to any ceph/inkscope package
  return get_key_from('/var/lib/ceph/restapi')

def admin():
  return get_key_from('/var/lib/ceph/admin')

def ids():
  _pillar_ = salt.pillar.get_pillar(
    __opts__,
    __grains__,
    __opts__.get('id'),
    __opts__['environment'],
  ).compile_pillar()

  p = subprocess.Popen('ceph -c /etc/ceph/%s.conf osd tree | ' \
      'awk \'{if (NR!=1)print $1}\'' %(_pillar_['ceph']['cluster']['name']),
      stdout=subprocess.PIPE,
      shell=True)
  out, err = p.communicate()
  return [n for n in map(int, out.split()) if n >= -1]
