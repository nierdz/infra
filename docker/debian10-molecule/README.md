# Quick reference

This image is made to provide **debian 10** in a molecule pipeline. It includes everything to run **ansible** locally and a fake init system to allow service module to work.

-	**Main repository containing all my docker images**: [nierdz docker images](https://github.com/nierdz/infra/tree/master/docker)

-	**Where to file issues**: [open issue in infra](https://github.com/nierdz/infra/issues)

- **Dockerfile**: [Dockerfile](https://github.com/nierdz/infra/blob/master/docker/debian10-molecule/Dockerfile)

# Usage

An example of a molecule pipeline using this image can be found here:

- [ansible-role-docker](https://github.com/nierdz/ansible-role-nginx/)

As you can see in this example, you need to **bind mount** `/sys/fs/cgroup` to make it work:

- [molecule.yml](https://github.com/nierdz/ansible-role-nginx/blob/master/molecule/default/molecule.yml)
