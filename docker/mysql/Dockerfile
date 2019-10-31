FROM mysql:8.0
ARG MYSQL_ROOT_PASSWORD
RUN apt-get update \
  && apt-get install -y \
  --no-install-recommends \
  ca-certificates \
  lsb-release \
  wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN wget "https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb" \
  && dpkg -i "percona-release_latest.$(lsb_release -sc)_all.deb" \
  && rm "percona-release_latest.$(lsb_release -sc)_all.deb"
RUN apt-get update \
  && apt-get install -y \
  --no-install-recommends \
  percona-toolkit\
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN printf "[client]\\nuser=root\\npassword=%s" ${MYSQL_ROOT_PASSWORD} > /root/.my.cnf \
  && chmod 400 /root/.my.cnf
