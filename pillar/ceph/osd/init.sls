base:
  ferm:
    open_ports:
      osd: "6800:6836"
osd:
  disks:
    /dev/sda: /var/local/osd_sda
    /dev/sdb: /var/local/osd_sdb
    /dev/sdc: /var/local/osd_sdc
    /dev/sdd: /var/local/osd_sdd
    /dev/sde: /var/local/osd_sde
    /dev/sdf: /var/local/osd_sdf
    /dev/sdg: /var/local/osd_sdg
    /dev/sdh: /var/local/osd_sdj
    /dev/sdi: /var/local/osd_sdi
    /dev/sdj: /var/local/osd_sdj
    /dev/sdk: /var/local/osd_sdk
    /dev/sdl: /var/local/osd_sdl
