FROM mysql:8.0-debian
LABEL version=1.1.11
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gnupg2 \
  lsb-release \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN curl -o "percona.deb" -SL "https://repo.percona.com/apt/percona-release_latest.generic_all.deb" \
  && dpkg -i "percona.deb" \
  && rm "percona.deb"
RUN apt-get update \
  && apt-get install -y \
  --no-install-recommends \
  percona-toolkit\
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
COPY docker-healthcheck /usr/local/bin/
HEALTHCHECK CMD ["docker-healthcheck"]
