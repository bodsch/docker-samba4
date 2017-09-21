#!/bin/sh

set -e

# -------------------------------------------------------------------------------------------------

HOSTNAME=$(hostname -f)

SAMBA_DC_DOMAIN=${SAMBA_DC_DOMAIN:-smb}
SAMBA_DC_REALM=${SAMBA_DC_REALM:-SAMBA.LAN}
SAMBA_DC_DNS_BACKEND=${SAMBA_DC_DNS_BACKEND:-SAMBA_INTERNAL}

# SAMBA_DC_DNS_BACKEND=BIND9_FLATFILE

SAMBA_OPTIONS=${SAMBA_OPTIONS:-}

[ -n "${SAMBA_HOST_IP}" ] && SAMBA_OPTIONS="${SAMBA_OPTIONS} --host-ip=${SAMBA_HOST_IP}"

SETUP_LOCK_FILE="/srv/etc/.setup.lock.do.not.remove"

pass=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c20; echo)

SAMBA_DC_ADMIN_PASSWD=${SAMBA_DC_ADMIN_PASSWD:-${pass}}
KERBEROS_PASSWORD=${KERBEROS_PASSWORD:-${pass}}

# echo "Samba password set to   : $SAMBA_DC_ADMIN_PASSWD"
# echo "Kerberos password set to: $KERBEROS_PASSWORD"

# we need the export for kdb5_util
export KERBEROS_PASSWORD
export SAMBA_DC_REALM
export HOSTNAME
export SETUP_LOCK_FILE

# -------------------------------------------------------------------------------------------------

setup() {

  if [ -f "${SETUP_LOCK_FILE}" ]
  then
    return
  fi

  if [ ${SAMBA_DC_DNS_BACKEND} == SAMBA_INTERNAL ]
  then
    rm -f /etc/supervisor.d/bind.ini
  fi

  run_bind() {

    if [ ${SAMBA_DC_DNS_BACKEND} == SAMBA_INTERNAL ]
    then
      return
    fi

    chmod +rw /var/log/named/

    /usr/sbin/named -c /etc/bind/named.conf -u named -f -g &

    sleep 2
  }

  kill_bind() {

    if [ ${SAMBA_DC_DNS_BACKEND} == SAMBA_INTERNAL ]
    then
      return
    fi

    pid=$(ps ax | grep named | grep -v grep | awk '{print $1}')

    if [ ! -z "${pid}" ]
    then
      kill -9 ${pid}

      sleep 2s
    fi
  }

  # Configure the AD DC
  if [ ! -f /srv/etc/smb.conf ]
  then
    mkdir -p /srv/etc /srv/lib /srv/log

    run_bind

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
    samba-tool domain exportkeytab \
      /etc/krb5.keytab \
      --principal ${HOSTNAME}\$

    # add dns-forwarder if required
    [ -n "${SAMBA_DNS_FORWARDER}" ] \
        && sed -i \
          "/\[global\]/a \\\dns forwarder = ${SAMBA_DNS_FORWARDER}" \
          /var/lib/samba/private/smb.conf

    sed -i '8 a         tls enabled  = yes' /etc/samba/smb.conf
    sed -i '9 a         tls keyfile  = tls/key.pem' /etc/samba/smb.conf
    sed -i '10 a         tls certfile = tls/cert.pem' /etc/samba/smb.conf
    sed -i '11 a         tls cafile   = tls/ca.pem' /etc/samba/smb.conf

    cp -ar /etc/samba       /srv/etc/
    cp -a  /etc/krb5*       /srv/etc/
    cp -a  /var/lib/krb5kdc /srv/

    # Mark samba as setup
    touch "${SETUP_LOCK_FILE}"

    kill_bind

    # smbd -b | egrep "LOCKDIR|STATEDIR|CACHEDIR|PRIVATE_DIR"
    # smbclient -L localhost -U% --configfile=/srv/etc/samba/smb.conf
    # smbclient //localhost/netlogon -UAdministrator -c 'ls' --configfile=/srv/etc/samba/smb.conf
    # ldapsearch -H ldaps://localhost -x -LLL -z 0 -D "Administrator@samba.lan"  -w "krazb4re+H5" -b "DC=samba,DC=lan"
  fi
}

start() {

  # Fix nameserver
  echo -e "search ${SAMBA_DC_REALM}\nnameserver 127.0.0.1" > /etc/resolv.conf
  echo -e "127.0.0.1 ${HOSTNAME} localhost" > /etc/hosts
  echo -e "$HOSTNAME" > /etc/hostname

  chmod -R 0700 /var/log/samba

  if [ ! -f "/var/lib/krb5kdc/principal" ]
  then
    cp -a /srv/krb5kdc   /var/lib/
    cp -a /srv/etc/krb5* /etc/
  fi

  [ -d /var/log/samba/cores ] || mkdir -pv /var/log/samba/cores

  if [ ! ${SAMBA_DC_DNS_BACKEND} == SAMBA_INTERNAL ]
  then

    [ -d /var/log/named ] || mkdir -p /var/log/named

    chown -Rv named: /var/bind /etc/bind /var/run/named /var/log/named
    chmod -Rv o-rwx /var/bind /etc/bind /var/run/named /var/log/named
  fi

  # samba --interactive --debuglevel=3 --debug-stderr --configfile=/srv/etc/samba/smb.conf
}

startSupervisor() {

#   echo -e "\n Starting Supervisor.\n\n"

  if [ -f /etc/supervisord.conf ]
  then
    /usr/bin/supervisord -c /etc/supervisord.conf >> /dev/null
  else
    echo " [E] no supervisord.conf found"
    exit 1
  fi
}

# -------------------------------------------------------------------------------------------------

run() {

  setup

  start

  startSupervisor
}

run
