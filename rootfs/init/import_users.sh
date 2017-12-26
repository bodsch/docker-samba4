
if [ "${TEST_USER}" != "true" ]
then
  return
fi

CSV_FILE="/init/build/import_users.csv"

add_user() {

  username="${1}"
  password="${2}"
  email="${3}"
  firstname="${4}"
  lastname="${5}"

  /usr/bin/samba-tool \
    user create \
      ${username} \
      ${password} \
      --mail-address="${email}" \
      --surname="${lastname}" \
      --given-name="${firstname}"
}

check_user() {

  username="${1}"

  realm=$(echo "${SAMBA_DC_REALM}" | tr '[:upper:]' '[:lower:]' | awk -F '.' '{ printf "DC=%s,DC=%s\n", $1, $2 }')

  ldapsearch \
    -H ldaps://localhost \
    -D "Administrator@{SAMBA_DC_REALM}" \
    -w "${SAMBA_DC_ADMIN_PASSWD}" \
    -b "CN=Users,${realm}" \
    "(&(objectClass=user)(sAMAccountName=${username}))" | grep displayName
}


if [ -f ${CSV_FILE} ]
then
  OLDIFS=$IFS
  IFS=";"
  sed -e '/^#/ d' -e '/^;/ d'  -e '/^ *$/ d' ${CSV_FILE} | while read username email firstname lastname password
  do
    echo "add $username"

    add_user "${username}" "${password}" "${email}" "${firstname}" "${lastname}"
  done

  IFS=$OLDIFS
fi
