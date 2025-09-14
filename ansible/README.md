# Ansible — Ops VM

Purpose: provision and harden the **ops VM** used for admin tasks (kubectl, docker, AWS CLI).

## Usage
1) Update `inventory.ini` with the ops host.
2) Run:
```bash
ansible-playbook -i inventory.ini playbooks/site.yml --syntax-check
ansible-playbook -i inventory.ini playbooks/site.yml
```

## What is installed
- docker
- kubectl
- awscli
- basic SSH hardening (PasswordAuthentication no)

> Do not commit secrets here.
