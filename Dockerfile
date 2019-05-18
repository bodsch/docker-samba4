
FROM alpine:3.9

EXPOSE 135 137/udp 138/udp 139 389 389/udp 445 464 636 3268 3269

ARG BUILD_DATE
ARG BUILD_VERSION
ARG SAMBA_VERSION

ENV \
  TZ=UTC

# ---------------------------------------------------------------------------------------

# hadolint ignore=DL3017,DL3018,DL3019
RUN \
  apk update  --quiet && \
  apk upgrade --quiet && \
  apk add     --quiet \
    bash \
    ca-certificates \
    expect \
    krb5 \
    krb5-server \
    openldap-clients \
    samba-dc \
    tdb \
    libxml2 \
    json-c \
    tzdata && \
  cp "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
  echo "${TZ}" > /etc/timezone && \
  mv /etc/samba/smb.conf /etc/samba/smb.conf-DIST && \
  mkdir -p /etc/samba/conf.d && \
  mkdir -p /var/log/samba/cores && \
  echo "export BUILD_DATE=${BUILD_DATE}"        > /etc/profile.d/samba.sh && \
  echo "export BUILD_VERSION=${BUILD_VERSION}" >> /etc/profile.d/samba.sh && \
  echo "export SAMBA_VERSION=${SAMBA_VERSION}" >> /etc/profile.d/samba.sh && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

#COPY --from=builder /usr/local /usr/local
COPY rootfs/ /

VOLUME [ "/etc/samba" "/var/lib/samba" ]

CMD ["/init/run.sh"]

HEALTHCHECK \
  --interval=5s \
  --timeout=10s \
  --retries=10 \
  CMD /init/health_check.sh

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@boone-schulz.de>" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="Samba4 Docker Image" \
  org.label-schema.description="Inofficial Samba4 Docker Image" \
  org.label-schema.url="https://www.samba.org/" \
  org.label-schema.vcs-url="https://github.com/bodsch/docker-samba4" \
  org.label-schema.vendor="Bodo Schulz" \
  org.label-schema.version=${SAMBA_VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="unlicense"

# ---------------------------------------------------------------------------------------
