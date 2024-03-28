# Quick reference

This image is made to provide **debian 12** in a molecule pipeline. It provides **systemd** to allow **ansible** service module to work.

-	**Main repository containing all my docker images**: [nierdz docker images](https://github.com/nierdz/infra/tree/master/docker)

-	**Where to file issues**: [open issue in infra](https://github.com/nierdz/infra/issues)

- **Dockerfile**: [Dockerfile](https://github.com/nierdz/infra/blob/master/docker/debian11-molecule/Dockerfile)

# Usage

## Molecule

An example of a role using a molecule pipeline and this image can be found here:

- [ansible-role-nextcloud](https://github.com/nierdz/ansible-role-netxcloud/)

## Docker

When using this image with docker you need ton run in **privileges** mode and to **bind mount** `/sys/fs/cgroup`.

`docker run --name debian10-molecule -d --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro nierdz/debian10-molecule`

## Podman

When using podman, you just run it without any particular privileges.

`podman run --name debian10-molecule -d docker.io/nierdz/debian10-molecule`
