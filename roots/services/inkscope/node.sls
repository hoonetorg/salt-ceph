sysprobe-deps:
  pkg.installed:
    - pkgs:
      - lshw
      - sysstat
      - python-psutil

sysprobe-unit-file:
  file.managed:
    - name: /etc/systemd/system/sysprobe.service
    - source: salt://templates/inkscope/base/sysprobe.service

sysprobe:
  service.running:
    - enable: True
    - require:
      - pkg: inkscope-pkgs
    - watch:
      - file: inkscope-opt-conf
