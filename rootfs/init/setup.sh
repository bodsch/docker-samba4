

setup () {

  # If $SAMBA_DC_ADMIN_PASSWD is not set, generate a password
  SAMBA_DC_ADMIN_PASSWD=${SAMBA_DC_ADMIN_PASSWD:-`(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20; echo) 2>/dev/null`}
  KERBEROS_PASSWORD=${KERBEROS_PASSWORD:-`(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20; echo) 2>/dev/null`}
  echo "Samba password set to: $SAMBA_DC_ADMIN_PASSWD"
  echo "Kerberos password set to: $KERBEROS_PASSWORD"

  # Provision domain
  [ -f /etc/samba/smb.conf ] && rm -f /etc/samba/smb.conf
  rm -rf /var/lib/samba/*
  mkdir -p /var/lib/samba/private

  samba-tool domain provision \
    --use-rfc2307 \
    --realm=${SAMBA_DC_REALM} \
    --adminpass=${SAMBA_DC_ADMIN_PASSWD} \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    $SAMBA_OPTIONS \
    --option="bind interfaces only"=yes

  #create LDAP INSECURE
  if [ "${LDAP_ALLOW_INSECURE,,}" == "true" ]
  then
    sed -i "/\[global\]/a \\\ldap server require strong auth = no" /etc/samba/smb.conf
  fi

  #update LDAP INSECURE
  # if [ "${LDAP_ALLOW_INSECURE,,}" == "true" ]; then
  #   sed -i "s/ldap server require strong auth = .*/ldap server require strong auth = yes/" /etc/samba/smb.conf
  # fi

  # Create Kerberos database
  rm -f /etc/krb5.conf
  ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf
  haveged -w 1024
  /usr/sbin/kdb5_util -P $KERBEROS_PASSWORD -r $SAMBA_DC_REALM create -s

  # Export kerberos keytab for use with sssd
  if [ "${OMIT_EXPORT_KEY_TAB}" != "true" ]
  then
    samba-tool domain exportkeytab /etc/krb5.keytab --principal ${HOSTNAME}\$
  fi

  # Move smb.conf
  [ -f /etc/samba/smb.conf ] && mv /etc/samba/smb.conf /var/lib/samba/private/smb.conf
  ln -sf /var/lib/samba/private/smb.conf /etc/samba/smb.conf

  # add dns-forwarder if required
  [ -n "$SAMBA_DNS_FORWARDER" ] \
      && sed -i "/\[global\]/a \\\dns forwarder = $SAMBA_DNS_FORWARDER" /var/lib/samba/private/smb.conf

  # Update dns-forwarder if required
  #[ -n "$SAMBA_DNS_FORWARDER" ] \
  #    && sed -i "s/dns forwarder = .*/dns forwarder = $SAMBA_DNS_FORWARDER/" /var/lib/samba/private/smb.conf

  # Mark samba as setup
  touch "${SETUP_LOCK_FILE}"

  # Setup only?
  [ -n "$SAMBA_SETUP_ONLY" ] && exit 127 || :

}

setup
