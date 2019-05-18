#!/bin/bash

bootstrap="/srv/etc/.setup.lock.do.not.remove"

set -eo pipefail


while true
do
  if [ ! -f ${bootstrap} ]
  then
    sleep 5s
  else
    break
  fi
done


if /usr/bin/smbclient \
  --configfile=/srv/etc/smb.conf \
  --authentication-file=/.smbclient.conf \
  --list=localhost \
  --max-protocol=SMB2
then
  exit 0
fi

exit 1
