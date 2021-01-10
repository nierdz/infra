FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive

LABEL version=2.1.0

# Install dependencies.
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      python3 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install docker-systemctl-replacement
RUN curl -o /bin/systemctl \
      -SL "https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/v1.5.4505/files/docker/systemctl3.py" \
    && chmod 0755 /bin/systemctl

CMD ["/bin/bash"]
