#
# pkgs
#

{% for pkg in pillar.base.pkgs %}
base pkg {{ pkg }}:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}
