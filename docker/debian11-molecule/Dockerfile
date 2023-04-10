FROM debian:11

ENV DEBIAN_FRONTEND noninteractive

LABEL version=2.3.1

# Install dependencies.
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      systemd \
      systemd-sysv \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Remove all systemd targets
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
      /etc/systemd/system/*.wants/* \
      /lib/systemd/system/local-fs.target.wants/* \
      /lib/systemd/system/sockets.target.wants/*udev* \
      /lib/systemd/system/sockets.target.wants/*initctl* \
      /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
      /lib/systemd/system/systemd-update-utmp*

VOLUME ["/sys/fs/cgroup"]
CMD ["/lib/systemd/systemd"]
