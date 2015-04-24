{% if data['act'] == 'accept'%}
add_host_in_dns:
  local.cmd.run:
    - tgt: 'dns-ceph-*'
    - arg:
      - echo data['id'] >> /tmp/added_hosts
{% endif %}
