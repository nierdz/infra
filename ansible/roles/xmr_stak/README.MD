# Ansible role to deploy xmr-stak

This role deploy [xmr-stak](https://github.com/fireice-uk/xmr-stak) to mine with CPU only

## Getting Started

- Download this role

- Add this in your `playbook.yml`:

```
- name: Provision xmr-stak
  hosts: xmr-stak
  roles:
    - { role: xmr-stak, tags: ['xmr-stak'] }
```

- Create a group name `xmr-stak`
- Change default vars according to your needs
- Run `ansible-playbook` as usual:
```
ansible-playbook playbook.yml -l xmr-stak
```
