
FROM alpine:3.7

EXPOSE 37/udp 53 88 135/tcp 137/udp 138/udp 139 389 445 464 636/tcp 1024-5000/tcp 3268/tcp 3269/tcp

ENV \
  TERM=xterm \
  BUILD_DATE="2017-12-22" \
  VERSION="4.7.3"

LABEL \
  version="1712" \
  maintainer="Bodo Schulz <bodo@boone-schulz.de>" \
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
  apk update --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add --quiet --no-cache \
    bind \
    ca-certificates \
    expect \
    krb5 \
    krb5-server \
    openldap-clients \
    samba-dc \
    supervisor && \
  mv /etc/samba/smb.conf /etc/samba/smb.conf-DIST && \
  mkdir -p /var/log/samba/cores && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

ADD rootfs/ /

CMD ["/init/run.sh"]
