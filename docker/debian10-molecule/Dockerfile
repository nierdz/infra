FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive

LABEL version=1.0.0

# Install dependencies.
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      gnupg \
      libffi-dev \
      libssl-dev \
      python3-dev \
      python3-pip \
      python3-setuptools \
      python3-wheel \
      sudo \
      systemd \
      systemd-sysv \
      wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Ansible via pip.
RUN pip3 install ansible==2.9.7

COPY initctl_faker .
RUN chmod +x initctl_faker && \
    rm -fr /sbin/initctl && \
    ln -s /initctl_faker /sbin/initctl

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN printf "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Make sure systemd doesn't start agettys on tty[1-6].
RUN rm -f /lib/systemd/system/multi-user.target.wants/getty.target

VOLUME ["/sys/fs/cgroup"]
CMD ["/lib/systemd/systemd"]