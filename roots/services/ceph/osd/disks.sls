#!pyobjects
# vim:set filetype=python:

import  itertools
import  subprocess
import  salt.exceptions

mon_id, mon_fqdn = mine(
        pillar('ceph:nodes:mon:master', ''), 'fqdn').items()[0]
admkey = mine(mon_id, 'bootstrap.admin')[mon_id]
cluster_name = pillar('ceph:cluster:name')

# this line means we have to mine.update the 'master' monitor everytime an osd
# is added or removed
idlist = mine(pillar('ceph:nodes:mon:master', ''), 'bootstrap.ids')[mon_id]
available_ids = iter((n for n in itertools.count() if n not in idlist))
idfile = '/var/lib/ceph/osd/id-file'

for disk in pillar('ceph:osd:disks'):
    osd_id_str = None
    try:
        with open(idfile) as fd:
            for line in fd:
                if disk in line:
                    fields = line.rstrip('\n').split()
                    if len(fields) < 2:
                        raise salt.exceptions.CommandExecutionError(
                                "formatting error in '%s'" %(idfile))
                    osd_id_str = fields[1]
    except IOError as e:
        raise salt.exceptions.CommandExecutionError(
                "'%s': %s" %(idfile, e))

    if not osd_id_str:
        osd_id = next(available_ids)
    else:
        try:
            osd_id = int(osd_id_str)
        except ValueError as e:
            raise salt.exceptions.CommandExecutionError(
                    "could not retrieve osd id from '%s': %s" %(e))

    Cmd.script('create-ceph-osd-%s' %osd_id,
            source='salt://templates/ceph/create_osd.sh',
            # only if disk is not partitioned
            unless="sed '1,/%s/d' /proc/partitions | grep -q %s" %(disk, disk),
            require=Pkg('ceph-pkgs'),
            template='jinja',
            context={
                'fqdn': grains('fqdn'),
                'disk': '/dev/%s' %disk,
                'idfile': idfile,
                'osd_id': osd_id,
                'cluster_name': cluster_name,
                'adm_key': admkey,
                }
            )

    mountpath = '/var/lib/ceph/osd/%s-%s' %(cluster_name, osd_id)
    p = subprocess.Popen('systemd-escape %s | tr -d \'\n\'' %(mountpath[1:]),
            stdout=subprocess.PIPE, shell=True)
    out, err = p.communicate()
    if not out:
        raise salt.exceptions.CommandExecutionError(
        "could not generate mountpoint path for osd %s ('%s')" %(osd_id, err))
    esc_mountpath = out

    # data partition mount unit
    File.managed('systemd-osd-%s-mount-unit' %osd_id,
            name='/etc/systemd/system/%s.mount' %esc_mountpath,
            source='salt://templates/ceph/osd-mountpoint.mount',
            template='jinja',
            context={
                'part': '/dev/%s2' %disk,
                'path': mountpath,
                },
            require=[
                Cmd('create-ceph-osd-%s' %osd_id),
                ],
            watch_in=[
                Cmd('reload-systemd-daemons'),
                Cmd('ceph-osd-%s-datapart-remount' %osd_id),
                ],
            )

    Cmd.run('ceph-osd-%s-datapart-mounted' %osd_id,
            name='systemctl start %s' %mountpath,
            unless='systemctl status %s' %mountpath,
            require=[
                File('systemd-osd-%s-mount-unit' %osd_id),
                Cmd('ceph-osd-%s-datapart-remount' %osd_id),
                ],
            )

    Cmd.wait('ceph-osd-%s-datapart-remount' %osd_id,
            name='systemctl restart %s' %mountpath,
            require=[
                File('systemd-osd-%s-mount-unit' %osd_id),
                ],
            )
    # not working, probably not good enough support for systemd yet
    #Service.running('ceph-osd-%s-datapart-mounted' %osd_id,
            #name="%s" %mountpath,
            #enable=True,
            #require=[
                #File('systemd-osd-%s-mount-unit' %osd_id),
                #Cmd('create-ceph-osd-%s' %osd_id),
                #Cmd('reload-systemd-daemons'),
                #],
            #)

    # ceph config file
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
    # ceph osd service
    Service.running('ceph-osd@%s' %osd_id,
            enable=True,
            require=[
                File('ceph-cluster-conf'),
                File('ceph-conf-global-section'),
                File('ceph-osd-unit-file'),
                File('ceph-conf-osd.%s-section' %osd_id),
                Cmd('create-ceph-osd-%s' %osd_id),
                Cmd('ceph-osd-%s-datapart-mounted' %osd_id),
                ],
            )

    osd_id = ''

Cmd.wait('reload-systemd-daemons',
        name='systemctl daemon-reload'
        )
