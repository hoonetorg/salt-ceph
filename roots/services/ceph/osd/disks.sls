#!pyobjects
# vim: filetype=python

import  subprocess
import  salt.exceptions

mon_id, mon_fqdn = mine(
        pillar('ceph:nodes:mon:master', ''), 'fqdn').items()[0]
admkey = mine(mon_id, 'bootstrap.admin')[mon_id]
cluster_name = pillar('ceph:cluster:name')
idfile = '/var/lib/ceph/osd/idlist'

for disk in pillar('ceph:osd:disks'):
    Cmd.script('create-ceph-osd-%s' %disk,
            source='salt://templates/ceph/create_osd.sh',
            # only if disk is not partitioned
            unless="sed '1,/%s/d' /proc/partitions | grep -q %s" %(disk, disk),
            require=Pkg('ceph-pkgs'),
            template='jinja',
            context={
                'fqdn': grains('fqdn'),
                'disk': '/dev/%s' %disk,
                'cluster_name': cluster_name,
                'adm_key': admkey,
                }
            )

    # get the possibly newly created osd id
    p = subprocess.Popen('grep /dev/%s %s | awk \'{print $2}\'' %(disk, idfile),
            stdout=subprocess.PIPE, shell=True)
    out, err = p.communicate()
    if not out:
        raise salt.exceptions.CommandExecutionError(
        "did not find osd id for disk '/dev/%s' in file '%s' ('%s')" %(disk, idfile, err))
    osd_id = out[:-1]

    File.blockreplace('ceph-conf-osd.%s-section' %osd_id,
            name='/etc/ceph/%s.conf' %cluster_name,
            marker_start='## DO NOT EDIT -- begin %s osd.%s disk /dev/%s' %(
                cluster_name, osd_id, disk),
            marker_end='## DO NOT EDIT -- end %s osd.%s disk /dev/%s' %(
                cluster_name, osd_id, disk),
            append_if_not_found='True',
            content='[osd.%s]' %osd_id,
            backup='.bak',
            show_changes='True',
            require=[
                File('ceph-cluster-conf'),
                Cmd('create-ceph-osd-%s' %disk),
                ],
            watch_in=[
                Service('ceph-osd@%s' %osd_id),
                Service('sysprobe'),
                ],
            )
    File.accumulated('ceph-conf-osd.%s-accumulator' %osd_id,
            filename='/etc/ceph/%s.conf' %cluster_name,
            text=[
                '# osd.%s config here' %osd_id,
                ],
            require_in=[
                File('ceph-conf-osd.%s-section' %osd_id)
                ],
            )
    Service.running('ceph-osd@%s' %osd_id,
            enable=True,
            require=[
                File('ceph-cluster-conf'),
                File('ceph-conf-global-section'),
                File('ceph-osd-unit-file'),
                File('ceph-conf-osd.%s-section' %osd_id),
                Cmd('create-ceph-osd-%s' %disk),
                ],
            )



#ceph-conf-osd.{disk}-section:
  #ceph_osd.blockreplace:
    #- name: /etc/ceph/{ cluster_name }.conf
    #- disk: /dev/{ disk }
    #- marker_start: "## DO NOT EDIT -- begin { cluster_name } osd disk /dev/{ disk }"
    #- marker_end: "## DO NOT EDIT -- end { cluster_name } osd disk /dev/{ disk }"
    #- append_if_not_found: True
    #- backup: '.bak'
    #- show_changes: True
    #- require:
      #- file: ceph-cluster-conf
      #- cmd: create-ceph-osd-{ disk }
    #- watch_in:
      #- service: ceph-osd@{ disk }
      #- service: sysprobe

#ceph-conf-osd.{disk}-section-accumulator:
  #ceph_osd.accumulated:
    #- filename: /etc/ceph/{ cluster_name }.conf
    #- text:
      #- "# disk /dev/{ disk }"
    #- require_in:
      #- ceph_osd: ceph-conf-osd.{disk}-section

#ceph-osd@{disk}:
  #ceph_osd.running:
    #- enable: True
    #- require:
      #- file: ceph-cluster-conf
      #- file: ceph-conf-global-section
      #- file: ceph-osd-unit-file
      #- ceph_osd: ceph-conf-osd.{ disk }-section
      #- cmd: create-ceph-osd-{ disk }
