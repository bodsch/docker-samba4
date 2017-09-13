
start () {
  # Fix nameserver
  echo -e "search ${SAMBA_REALM}\nnameserver 127.0.0.1" > /etc/resolv.conf
  echo -e "127.0.0.1 $HOSTNAME" > /etc/hosts
  echo -e "$HOSTNAME" > /etc/hostname

  # setup
  if [ ! -f "${SETUP_LOCK_FILE}" ]
  then
    setup
  fi

  # ssh
  if [ -f "/init/runssh.sh" ]
  then
    /init/runssh.sh
  fi

  # Recreate Kerberos database
  if [ ! -f "/var/lib/krb5kdc/principal" ]
  then
    rm -f /etc/krb5.conf
    ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf
    haveged -w 1024

    /usr/sbin/kdb5_util \
      create -s \
      -P $KERBEROS_PASSWORD \
      -r $SAMBA_REALM

    samba-tool domain \
      exportkeytab /etc/krb5.keytab \
      --principal ${HOSTNAME}\$
  fi

  # run
  # /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
}

start
