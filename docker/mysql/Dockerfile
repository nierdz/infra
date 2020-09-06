FROM mysql:8.0
LABEL version=1.0.2
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y \
  --no-install-recommends \
  ca-certificates \
  curl \
  gnupg2 \
  lsb-release \
  wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN wget "https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb" \
  && dpkg -i "percona-release_latest.$(lsb_release -sc)_all.deb" \
  && rm "percona-release_latest.$(lsb_release -sc)_all.deb"
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y \
  --no-install-recommends \
  percona-toolkit\
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
