
CSV_FILE="/init/build/import_users.csv"

add_user() {

  username="${1}"
  password="${2}"
  email="${3}"
  firstname="${4}"
  lastname="${5}"

  if [[ $(check_user ${username}) -eq 0 ]]
  then
    log_info "add user '${username}'"

    /usr/bin/samba-tool user create \
      ${username} \
      ${password} \
      --configfile=${SAMBA_CONF_FILE} \
      --mail-address="${email}" \
      --surname="${lastname}" \
      --given-name="${firstname}"
  fi
}

check_user() {

  username="${1}"

#   realm=$(echo "${SAMBA_DC_REALM}" | tr '[:upper:]' '[:lower:]' | awk -F '.' '{ printf "DC=%s,DC=%s\n", $1, $2 }')
#
#   user=$(ldapsearch \
#     -H ldaps://localhost \
#     -D "Administrator@{SAMBA_DC_REALM}" \
#     -w "${SAMBA_DC_ADMIN_PASSWD}" \
#     -b "CN=Users,${realm}" \
#     "(&(objectClass=user)(sAMAccountName=${username}))" | grep displayName)

  /usr/bin/samba-tool user list \
    --configfile=${SAMBA_CONF_FILE} \
    | grep -c ${username}
}

create_healthcheck_user() {

#  export SAMBA_HEALTH_USER="healthcheck"
#  export SAMBA_HEALTH_PASS="1bQFxTUUerxY"

  add_user "healthcheck" "1bQFxTUUerxY" "health@smb.lan" "health" "check"

  cat > /.smbclient.conf << EOF
username=healthcheck
password=1bQFxTUUerxY
EOF
}

user() {

  if [[ -f ${CSV_FILE} ]]
  then
    OLDIFS=$IFS
    IFS=";"
    sed -e '/^#/ d' -e '/^;/ d'  -e '/^ *$/ d' ${CSV_FILE} | while read username email firstname lastname password
    do
      add_user "${username}" "${password}" "${email}" "${firstname}" "${lastname}"
    done

    IFS=$OLDIFS
  fi
}

create_healthcheck_user

[[ "${TEST_USER}" != "true" ]] && return

user
