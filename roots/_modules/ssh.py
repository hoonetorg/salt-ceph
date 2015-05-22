#!/usr/bin/env python

import  os

def __virtual__():
  ''' only load if host has an ssh key '''
  if os.path.exists('/root/.ssh/id_rsa.pub'):
    return 'ssh'
  return False

def pubkey():
  with open('/root/.ssh/id_rsa.pub') as fd:
    return fd.read()
