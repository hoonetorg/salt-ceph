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
idfile = '/var/lib/ceph/osd/id-file'

def whoami():
    return inspect.stack()[1][3]

def removal_fail(identifier, reason):
    err_str = ("failed to remove osd from identifier '%s': %s" %(
        identifier, reason)).replace("'", "'\"'\"'")

    Cmd.run('fail of \'%s\' osd removal' %(identifier),
            name=("echo '%s' > /dev/stderr; false" %(err_str))
            )

def remove_osd(id_to_remove, disk, identifier=''):
    Service.dead('stop osd.%d' %id_to_remove,
            name='ceph-osd@%d.service' %id_to_remove
            )
    Cmd.script('remove osd.%d %s' %(id_to_remove, identifier),
            name='salt://templates/ceph/remove_osd.sh',
            args='-i %d -d %s -f %s -c %s' %(
                id_to_remove, disk, grains('fqdn'), cluster_name),
            template='jinja',
            context={
                'adm_key': admkey,
                },
            require=[
                Service('stop osd.%d' %id_to_remove),
                ],
            )
    Cmd.wait('remove osd.%d %s from idfile' %(id_to_remove, identifier),
            name='sed -i \'/%d$/d\' %s' %(id_to_remove, idfile),
            watch=[
                Cmd('remove osd.%d %s' %(id_to_remove, identifier)),
                ],
            require=[
                Cmd('remove osd.%d %s' %(id_to_remove, identifier)),
                ],
            )

    mountpath = '/var/lib/ceph/osd/%s-%d' %(cluster_name, id_to_remove)
    p = subprocess.Popen('systemd-escape %s | tr -d \'\n\'' %(mountpath[1:]),
            stdout=subprocess.PIPE, shell=True)
    out, err = p.communicate()
    if not out:
        cmdname = 'echo "failed to generate systemd mountpath for osd.%d: ' \
                '%s" > /dev/stderr; false' %(id_to_remove, err)

        Cmd.run('osd.%d %s systemd mountpoint removal' %(id_to_remove, identifier),
                name=cmdname,
                watch=[
                    Cmd('remove osd.%d %s' %(id_to_remove, identifier)),
                    ],
                require=[
                    Cmd('remove osd.%d %s' %(id_to_remove, identifier)),
                    ],
                )
    else:
        esc_mountpath = out
        Mount.unmounted('unmount osd.%d %s mountpoint' %(id_to_remove, identifier),
                name=mountpath,
                device=disk,
                require=[
                    Cmd('remove osd.%d %s' %(id_to_remove, identifier)),
                    ],
                )
        File.absent('remove osd.%d %s systemd mount unit' %(id_to_remove, identifier),
                name='/etc/systemd/system/%s.mount' %esc_mountpath,
                require=[
                    Mount('unmount osd.%d %s mountpoint' %(id_to_remove, identifier)),
                    ],
                )



def get_disk_and_id(**kwargs):
    to_find = None
    for osd_key in [
            'id_to_remove',
            'disk_to_remove',
            ]:
        if osd_key in kwargs:
            to_find = kwargs[osd_key]
            break

    if not to_find:
        return (None, None, "invalid arguments in function '%s'" %(whoami()))

    if isinstance(to_find, int):
        to_find = '%d' %to_find
    osd_id_str, disk_str, err_str = None, None, "'%s' not found in %s" %(to_find, idfile)
    try:
        with open(idfile) as fd:
            i = 1
            for line in fd:
                if to_find in line:
                    fields = line.rstrip('\n').split()
                    if len(fields) < 2:
                        err_str = "formatting error in %s on line %d" %(
                                idfile, i)
                    else:
                        osd_id_str = fields[1]
                        disk_str = fields[0]
                        err_str = 'success'
                    break
                i += 1
    except IOError as e:
        return (None, None, "%s: %s" %(idfile, e))

    return (osd_id_str, disk_str, err_str)


for id_to_remove in pillar('ceph_run:osd:remove:ids'):
    osd_id_str, disk_str, err_str = get_disk_and_id(id_to_remove=id_to_remove)

    if not osd_id_str or not disk_str:
        removal_fail(id_to_remove, err_str)
        continue
    try:
        osd_id = int(osd_id_str)
    except ValueError as e:
        removal_fail("could not retrieve osd id from '%s': %s" %(idfile, e))
        continue

    remove_osd(osd_id, disk_str, '(ids pillar)')

for disk in pillar('ceph_run:osd:remove:disks'):
    osd_id_str, disk_str, err_str = get_disk_and_id(disk_to_remove=disk)

    if not osd_id_str or not disk_str:
        removal_fail(disk, err_str)
        continue
    try:
        osd_id = int(osd_id_str)
    except ValueError as e:
        removal_fail(disk, "%s" %(e))
        continue

    remove_osd(osd_id, disk_str, '(disks pillar)')
