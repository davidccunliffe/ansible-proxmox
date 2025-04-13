#!/bin/bash

# ansible-playbook -i inventories/home-lab/hosts.yml playbooks/setup.yml --ask-vault-pass
ansible-playbook ./playbooks/setup.yml -i ./inventories/${1} -t ${2:-all}
