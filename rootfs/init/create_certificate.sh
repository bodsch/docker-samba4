
TLS_DIR="/var/lib/samba/private/tls"

create_certificate() {

  HOSTNAME=${HOSTNAME-localhost}

  CERT_C="DE"
  CERT_ST="XXXX"
  CERT_L="XXXX"
  CERT_O="self signed"
  CERT_CN=${HOSTNAME}

  if [ ! -e "${TLS_DIR}/cert.pem" ] || [ ! -e "${TLS_DIR}/key.pem" ]
  then
    echo " [i] generating self signed cert"
    openssl \
      req \
      -x509 \
      -newkey \
      rsa:4086 \
      -subj "/C=${CERT_C}/ST=${CERT_ST}/L=${CERT_L}/O=${CERT_O}/CN=${CERT_CN}" \
      -keyout "${TLS_DIR}/key.pem" \
      -out "${TLS_DIR}/cert.pem" \
      -days 3650 \
      -nodes \
      -sha256
  fi
}

