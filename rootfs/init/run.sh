#!/bin/sh
# Copyright 2017-TODAY LasLabs Inc.
# License Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0.html).

set -x
set -e

fix() {

LDAP_ALLOW_INSECURE=${LDAP_ALLOW_INSECURE:-false}
SAMBA_REALM=${SAMBA_REALM:-SAMBA.LAN}

# Populate $SAMBA_OPTIONS
SAMBA_OPTIONS=${SAMBA_OPTIONS:-}

HOSTNAME=${HOSTNAME:-"hostname -f"}

[ -n "${SAMBA_DOMAIN}" ] \
    && SAMBA_OPTIONS="${SAMBA_OPTIONS} --domain=$SAMBA_DOMAIN" \
    || SAMBA_OPTIONS="${SAMBA_OPTIONS} --domain=${SAMBA_REALM%%.*}"

[ -n "${SAMBA_HOST_IP}" ] && SAMBA_OPTIONS="${SAMBA_OPTIONS} --host-ip=${SAMBA_HOST_IP}"

SETUP_LOCK_FILE="/var/lib/samba/private/.setup.lock.do.not.remove"

. /init/setup.sh
. /init/start.sh

exit 0
}

# -----------------------------------------------------------

SAMBA_DC_DOMAIN=${SAMBA_DC_DOMAIN:-smb}
SAMBA_DC_REALM=${SAMBA_DC_REALM:-SAMBA.LAN}
SAMBA_DC_DNS_BACKEND=${SAMBA_DC_DNS_BACKEND:-SAMBA_INTERNAL}
SAMBA_OPTIONS=${SAMBA_OPTIONS:-}
[ -n "${SAMBA_HOST_IP}" ] && SAMBA_OPTIONS="${SAMBA_OPTIONS} --host-ip=${SAMBA_HOST_IP}"

SETUP_LOCK_FILE="/var/lib/samba/private/.setup.lock.do.not.remove"

pass=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c20; echo)

SAMBA_DC_ADMIN_PASSWD=${SAMBA_DC_ADMIN_PASSWD:-${pass}}
KERBEROS_PASSWORD=${KERBEROS_PASSWORD:-${pass}}
# SAMBA_DC_ADMIN_PASSWD="${pass}"
# KERBEROS_PASSWORD="${pass}"

echo "Samba password set to   : $SAMBA_DC_ADMIN_PASSWD"
echo "Kerberos password set to: $KERBEROS_PASSWORD"

# we need the export for kdb5_util
export KERBEROS_PASSWORD

# [ -n "${SAMBA_DC_DOMAIN}" ] \
#     && SAMBA_DC_DOMAIN="$(echo ${SAMBA_DC_DOMAIN} | tr [A-Z] [a-z])" \
#     || SAMBA_DC_DOMAIN="$(echo ${SAMBA_DC_REALM%%.*} | tr [A-Z] [a-z])"

COMMAND=ash

# Add $COMMAND if needed
if [ "${1:0:1}" = '-' ]
then
	set -- $COMMAND "$@"
fi

setup () {

# Configure the AD DC
if [ ! -f /samba/etc/smb.conf ]
then
  mkdir -p /samba/etc /samba/lib /samba/log

  echo "${SAMBA_DC_DOMAIN} - Begin Domain Provisioning"
  samba-tool domain provision \
    ${SAMBA_OPTIONS} \
    --use-rfc2307 \
    --domain="${SAMBA_DC_DOMAIN}" \
    --realm="${SAMBA_DC_REALM}" \
    --server-role=dc \
    --adminpass="${SAMBA_DC_ADMIN_PASSWD}" \
    --dns-backend="${SAMBA_DC_DNS_BACKEND}"

  echo "${SAMBA_DC_DOMAIN} - Domain Provisioned Successfully"

  cp -v /var/lib/samba/private/krb5.conf /etc/krb5.conf

  # Create Kerberos database
  expect /init/build/kdb5_util_create.expect

  # Export kerberos keytab for use with sssd
  samba-tool domain exportkeytab /etc/krb5.keytab --principal ${HOSTNAME}\$
#  sed -i "s/SAMBA_REALM/${SAMBA_REALM}/" /etc/sssd/sssd.conf

  # Move smb.conf
#   [ -f /etc/samba/smb.conf ] && mv /etc/samba/smb.conf /var/lib/samba/private/smb.conf
#   ln -sf /var/lib/samba/private/smb.conf /etc/samba/smb.conf

  # add dns-forwarder if required
  [ -n "$SAMBA_DNS_FORWARDER" ] \
      && sed -i "/\[global\]/a \\\dns forwarder = $SAMBA_DNS_FORWARDER" /var/lib/samba/private/smb.conf

  # Mark samba as setup
  touch "${SETUP_LOCK_FILE}"
fi
}

start() {

  # Fix nameserver
  echo -e "search ${SAMBA_REALM}\nnameserver 127.0.0.1" > /etc/resolv.conf
  echo -e "127.0.0.1 $HOSTNAME" > /etc/hosts
  echo -e "$HOSTNAME" > /etc/hostname

  [ -d /var/log/samba/cores ] || mkdir -p /var/log/samba/cores

  chmod -R 0700 /var/log/samba

  # setup
  if [ ! -f "${SETUP_LOCK_FILE}" ]
  then
    setup
  fi

#   # Recreate Kerberos database
#   if [ ! -f "/var/lib/krb5kdc/principal" ]
#   then
#     rm -f /etc/krb5.conf
#     ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf
#     haveged -w 1024
#
#     /usr/sbin/kdb5_util \
#       create -s \
#       -P $KERBEROS_PASSWORD \
#       -r $SAMBA_REALM
#
#     samba-tool domain \
#       exportkeytab /etc/krb5.keytab \
#       --principal ${HOSTNAME}\$
#   fi

  # Move smb.conf
#  [ -f /etc/samba/smb.conf ] && mv /etc/samba/smb.conf /var/lib/samba/private/smb.conf
#  ln -s /var/lib/samba/private/smb.conf /etc/samba/smb.conf

  [ -f /var/lib/samba/private/smb.conf ] && cp -v /var/lib/samba/private/smb.conf /etc/samba/smb.conf

  samba --debuglevel=3 --interactive
}

start


#
# if [ "$1" = 'samba' ]
# then
#   exec samba --debuglevel=2 --interactive
# else
#   start
# fi
#
# # Assume that user wants to run their own process,
# # for example a `bash` shell to explore this image
# exec "$@"
