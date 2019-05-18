#!/bin/bash

SAMBA_DC_DOMAIN=${SAMBA_DC_DOMAIN:-smb}
SAMBA_DC_REALM=${SAMBA_DC_REALM:-MATRIX.LAN}

SAMBA_DC_ADMIN_PASSWD=${SAMBA_DC_ADMIN_PASSWD:-krazb4re+H5}

SMB_HOST="${SMB_HOST:-samba4}"
CSV_FILE="/init/build/import_users.csv"

cat > /.smbclient.conf << EOF
username=Administrator
password=${SAMBA_DC_ADMIN_PASSWD}
EOF

cat /.smbclient.conf

if [[ -f /etc/openldap/ldap.conf ]]
then
  echo "" >> /etc/openldap/ldap.conf
  echo "TLS_CACERT  /etc/ssl/certs/ca-certificates.crt" >> /etc/openldap/ldap.conf
  echo "TLS_REQCERT ALLOW" >> /etc/openldap/ldap.conf
fi

realm=$(echo "${SAMBA_DC_REALM}" | tr '[:upper:]' '[:lower:]' | awk -F '.' '{ printf "DC=%s,DC=%s\n", $1, $2 }')

check_user() {

  username="${1}"

  user=$(ldapsearch \
    -H ldaps://${SMB_HOST} \
    -D "Administrator@${SAMBA_DC_REALM}" \
    -w "${SAMBA_DC_ADMIN_PASSWD}" \
    -b "CN=Users,${realm}" \
    "(&(objectClass=user)(sAMAccountName=${username}))" | grep displayName)

  echo "found  '${user}'"
}

smbclient --list=${SMB_HOST} --authentication-file=/.smbclient.conf  --max-protocol=SMB2

echo ""

smbclient //${SMB_HOST}/sysvol --authentication-file=/.smbclient.conf --command='ls'

echo ""

ldapsearch \
  -H ldaps://${SMB_HOST} \
  -D "Administrator@${SAMBA_DC_REALM}" \
  -w "${SAMBA_DC_ADMIN_PASSWD}" \
  -b "${realm}" \
  "(&(objectClass=user))" | grep displayName

echo ""

ldapsearch \
  -H ldaps://${SMB_HOST} \
  -D "Administrator@${SAMBA_DC_REALM}" \
  -w "${SAMBA_DC_ADMIN_PASSWD}" \
  -b "${realm}" \
  -z 0 | grep -e "^dn: "

echo ""

if [[ -f ${CSV_FILE} ]]
then
  OLDIFS=$IFS
  IFS=";"
  sed -e '/^#/ d' -e '/^;/ d'  -e '/^ *$/ d' ${CSV_FILE} | while read username email firstname lastname password
  do
    check_user "${username}"
  done

  IFS=$OLDIFS
fi
