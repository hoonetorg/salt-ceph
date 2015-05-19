sysprobe-deps:
  pkg.installed:
    - pkgs:
      - lshw
      - sysstat
      - python-psutil

sysprobe:
  service.running:
    - enable: True
    - require:
      - pkg: inkscope-pkgs
    - watch:
      - file: inkscope-opt-conf
