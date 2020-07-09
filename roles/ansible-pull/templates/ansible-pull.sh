#!/bin/bash

{% macro run_playbook(url, name, branch=none) %}
  start=$(date +%s)
  ansible-pull -U {{ url }} {% if branch is not none %}-C {{ branch}} {% endif %} -d /var/run/ansible/{{ name }}&> /var/log/ansible-{{ name }}.log
  code=$?

  if [ -d /var/lib/prometheus/node-exporter ]; then
    prom_file="/var/lib/prometheus/node-exporter/ansible-playbook-{{ name }}.prom"
    labels="playbook=\"{{ name }}\", playbook_url=\"{{ url }}\", playbook_branch=\"{{ branch }}\""
    echo "# HELP ansible_playbook_exit_code The exit code of ansible-pull" > ${prom_file}
    echo "# TYPE ansible_playbook_exit_code gauge" >> ${prom_file}
    echo "ansible_playbook_exit_code{${labels}} ${code}" >> ${prom_file}

    echo "# HELP ansible_playbook_time The time a playbook took to run, in seconds" >> ${prom_file}
    echo "# TYPE ansible_playbook_time gauge" >> ${prom_file}
    echo "ansible_playbook_time{${labels}} $(expr $(date +%s) - ${start})" >> ${prom_file}
  fi
{%- endmacro %}

if [ "$1" == "nodisown" ]; then
  # Sometimes the $PATH gets messed up in cron, so lets start by setting the record straight
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

{{ run_playbook(ansible_local.pull.repo, "basic", ansible_local.pull.branch) }}
{% if ansible_fqdn in additional_playbooks %}
{% for playbook in additional_playbooks[ansible_fqdn] %}
{{ run_playbook(playbooks[playbook.name], playbook.name, ansible_local.pull.branch) }}
{% endfor %}
{% endif %}

{% if "additional_playbooks" in ansible_local %}
{% for playbook in ansible_local.additional_playbooks %}
{{ run_playbook(playbook.url, playbook.name, playbook.branch) }}
{% endfor %}
{% endif %}
else
  $0 nodisown & disown
fi
