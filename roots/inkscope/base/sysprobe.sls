sysprobe-deps:
  pkg.installed:
    - pkgs:
      - lshw
      - sysstat
      - python-psutil

sysprobe:
  service.running:
    - require:
      - pkg: inkscope-pkgs
    - watch:
      - file: inkscope-opt-conf
