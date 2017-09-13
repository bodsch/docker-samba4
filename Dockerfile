
FROM alpine:3.6

MAINTAINER Bodo Schulz <bodo@boone-schulz.de>

ENV \
  ALPINE_MIRROR="mirror1.hs-esslingen.de/pub/Mirrors" \
  ALPINE_VERSION="v3.6" \
  TERM=xterm \
  BUILD_DATE="2017-09-09" \
  VERSION=""

EXPOSE 37/udp 53 88 135/tcp 137/udp 138/udp 139 389 445 464 636/tcp 1024-5000/tcp 3268/tcp 3269/tcp

# ---------------------------------------------------------------------------------------

RUN \
  echo "http://${ALPINE_MIRROR}/alpine/${ALPINE_VERSION}/main"       > /etc/apk/repositories && \
  echo "http://${ALPINE_MIRROR}/alpine/${ALPINE_VERSION}/community" >> /etc/apk/repositories && \
  apk --no-cache update && \
  apk --no-cache upgrade && \
  apk --no-cache add \
    expect \
    krb5-server \
    samba-dc && \
  mv /etc/samba/smb.conf /etc/samba/smb.conf-DIST && \
  mkdir -p /var/log/samba/cores

#  find /var/lib/samba/ -type f -delete
# RUN \
#   rm -rf /var/cache/apk/*

ADD rootfs/ /

ENTRYPOINT ["/init/run.sh"]
# CMD ["samba"]
