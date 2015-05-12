base:
  '* and not ceph-adm-*':
     - match: compound
     - ceph.base.pkgs
     - inkscope.base.sysprobe
   '*':
     - ceph.base
     - inkscope.base
   'ceph-adm-*':
     - ceph.base.ferm
     - ceph.adm
     - inkscope.admviz
   'ceph-mds-*':
     - ceph.base.ferm
     - ceph.mds
   'ceph-mon-*':
     - ceph.base.ferm
     - ceph.monitor
   'ceph-mon-1':
     - inkscope.monitor
   'ceph-osd-*':
     - ceph.base.ferm
     - ceph.osd
# '*':
#    {% for k, v in pillar.get('services', {}).iteritems() %}
#    {% if v %}
#    - services.{{ k }}
#    {% endif %}
#    {% endfor %}
