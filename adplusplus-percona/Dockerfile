FROM percona:5.7
ARG MYSQL_ROOT_PASSWORD
RUN apt-get update \
	&& apt-get install -y \ 
	--no-install-recommends \
	percona-toolkit=3.0.12-1.stretch \
	&& rm -rf /var/lib/apt/lists/*
RUN printf "[client]\\nuser=root\\npassword=%s" ${MYSQL_ROOT_PASSWORD} > /root/.my.cnf \
	&& chmod 400 /root/.my.cnf
