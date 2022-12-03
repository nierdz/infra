FROM debian:11-slim as build
ENV HUGO_VERSION 0.107.0
ARG LOCAL=0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008,DL3015
RUN apt-get update \
  && apt-get install -y \
  wget \
  && rm -rf /var/lib/apt/lists/*
RUN wget -qO- -SL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz" \
    | tar -xzC /bin \
    && rm -f /bin/README.md /bin/LICENSE
COPY ./www /www
WORKDIR /www
RUN if [[ $LOCAL -eq 1 ]]; then \
      /bin/hugo --baseUrl=https://igln.local/; \
    else \
      /bin/hugo --baseUrl=https://igln.fr/; \
    fi

FROM nginx:1.23
LABEL version=2.0.1
COPY --from=build /www/public /var/www
