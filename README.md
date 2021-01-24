[![CI Status](https://github.com/nierdz/infra/workflows/CI/badge.svg?branch=master)](https://github.com/nierdz/infra/actions?query=workflow%3ACI)
[![DOCKER-BUILD Status](https://github.com/nierdz/infra/workflows/DOCKER-BUILD/badge.svg?branch=master)](https://github.com/nierdz/infra/actions?query=workflow%3ADOCKER-BUILD)
[![DOCKER-PUSH Status](https://github.com/nierdz/infra/workflows/DOCKER-PUSH/badge.svg?branch=master)](https://github.com/nierdz/infra/actions?query=workflow%3ADOCKER-PUSH)

# Infra
All my personal infrastructure as code is here

### Run ansible
For example to run only on `srv1.igln.fr` and to target `mysql` tag:

```
ANSIBLE_INVENTORY_GROUP=srv1.igln.fr ANSIBLE_TAGS=mysql make ansible-run
```
