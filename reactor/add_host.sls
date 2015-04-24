{% if data['act'] == 'accept' %}
add_host_in_dns:
  local.cmd.run:
    - tgt: 'id:dns-ceph-*'
    - arg:
      - touch /tmp/{{ data['id'] }}
{% endif %}
