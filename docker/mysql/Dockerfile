FROM mysql:5.7
ARG MYSQL_ROOT_PASSWORD
RUN apt-get update \
	&& apt-get install -y \
	lsb-release \
	wget
RUN wget https://repo.percona.com/apt/percona-release_0.1-10.$(lsb_release -sc)_all.deb \
	&& dpkg -i percona-release_0.1-10.$(lsb_release -sc)_all.deb \
	&& rm percona-release_0.1-10.$(lsb_release -sc)_all.deb
RUN apt-get update \
	&& apt-get install -y \ 
	--no-install-recommends \
	percona-toolkit=3.0.13-1.stretch \
	&& rm -rf /var/lib/apt/lists/*
RUN printf "[client]\\nuser=root\\npassword=%s" ${MYSQL_ROOT_PASSWORD} > /root/.my.cnf \
	&& chmod 400 /root/.my.cnf
