
FROM alpine:3.9

ARG BUILD_DATE
ARG BUILD_VERSION
ARG SAMBA_VERSION

# ---------------------------------------------------------------------------------------

RUN \
  apk update --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add --quiet --no-cache \
    bash \
    ca-certificates \
    samba-client \
    openldap-clients && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

ADD rootfs/ /
ADD test/ /

CMD ["/tests.sh"]

# ---------------------------------------------------------------------------------------
