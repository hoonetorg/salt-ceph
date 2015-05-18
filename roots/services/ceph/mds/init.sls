include:
  - services.ceph.base.pkgs

ceph-mds-file:
  file.managed:
    - name: {{ pillar.mds.mds_dir }}
    - contents: "{{ grains.localhost }}"
    - makedirs: True
    - watch_in:
      - event: fire add_mds event

fire-add-mds-event:
  event.wait:
    - name: 'ceph/mds/add'
