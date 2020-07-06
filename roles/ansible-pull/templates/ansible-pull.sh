#!/bin/bash

if [ "$1" == "nodisown" ]; then
  # Sometimes the $PATH gets messed up in cron, so lets start by setting the record straight
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  if [[ -d /usr/ansible ]]; then rm -rf /usr/ansible; fi
  ansible-pull -U {{ ansible_local.pull.repo }} -C {{ ansible_local.pull.branch }} -d /var/run/ansible/basic &> /var/log/ansible.log
  code=$?

  if [[ "$code" -ne "0" ]]; then
    # ansible localhost -m irc -a "server=irc.oftc.net use_ssl=yes port=6697 channel=# msg='[$(hostname -f)] Ansible Pull failed.'  nick=ansible-$RANDOM color=red timeout=60"
    exit 1
  fi

{% if ansible_fqdn in additional_playbooks %}
{% for playbook in additional_playbooks[ansible_fqdn] %}
  ansible-pull -U {{ playbooks[playbook.name] }} {% if 'branch' in playbook %}-C {{ playbook.branch}} {% endif %} -d /var/run/ansible/{{playbook.name}}&> /var/log/ansible-{{ playbook.name }}.log
  code=$?

  if [[ "$code" -ne "0" ]]; then
    # ansible localhost -m irc -a "server=irc.oftc.net use_ssl=yes port=6697 channel=# msg='[$(hostname -f)] ansible-pull failed with additional playbook {{ playbook.name }}'  nick=ansible-$RANDOM color=red"
    exit 1
  fi

{% endfor %}
{% endif %}
    # ansible localhost -m irc -a "server=irc.oftc.net use_ssl=yes port=6697 channel=# msg='[$(hostname -f)] Ansible Pull successfully ran'  nick=ansible-$RANDOM color=green"

else
  $0 nodisown & disown
fi
