
FROM alpine:3.6

MAINTAINER Bodo Schulz <bodo@boone-schulz.de>

EXPOSE 37/udp 53 88 135/tcp 137/udp 138/udp 139 389 445 464 636/tcp 1024-5000/tcp 3268/tcp 3269/tcp

ENV \
  ALPINE_MIRROR="mirror1.hs-esslingen.de/pub/Mirrors" \
  ALPINE_VERSION="v3.6" \
  TERM=xterm \
  BUILD_DATE="2017-09-21" \
  VERSION="4.6.4"

LABEL \
  version="1709" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="Samba4 Docker Image" \
  org.label-schema.description="Inofficial Samba4 Docker Image" \
  org.label-schema.url="https://www.samba.org/" \
  org.label-schema.vcs-url="https://github.com/bodsch/docker-samba4" \
  org.label-schema.vendor="Bodo Schulz" \
  org.label-schema.version=${VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="unlicense"

# ---------------------------------------------------------------------------------------

RUN \
  echo "http://${ALPINE_MIRROR}/alpine/${ALPINE_VERSION}/main"       > /etc/apk/repositories && \
  echo "http://${ALPINE_MIRROR}/alpine/${ALPINE_VERSION}/community" >> /etc/apk/repositories && \
  apk --no-cache update && \
  apk --no-cache upgrade && \
  apk --no-cache add \
    bind \
    expect \
    krb5 \
    krb5-server \
    samba-dc \
    supervisor && \
  mv /etc/samba/smb.conf /etc/samba/smb.conf-DIST && \
  mkdir -p /var/log/samba/cores && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

ADD rootfs/ /

CMD ["/init/run.sh"]
