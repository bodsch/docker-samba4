#!/bin/sh

PID_FILE="/tmp/dnsmasq.pid"

sigint_handler() {

  pkill -15 $(cat ${PID_FILE})
  exit
}

trap sigint_handler SIGINT QUIT KILL

start() {

#  rm -f /app/dnsmasq.addn.docker
  touch /app/dnsmasq.addn.docker
  chmod a+rw /app/dnsmasq.addn.docker

  /usr/sbin/dnsmasq --user=root --pid-file=${PID_FILE} --log-facility=/tmp/dnsmasq.log
}

start

while true
do
  $@ &
  PID=$!
  inotifywait --timeout 1 --outfile=/tmp/ionotify.log --event modify --event create /app/dnsmasq.addn.docker

  if [ -f ${PID_FILE} ]
  then
    pkill -1 -P $(cat ${PID_FILE})
#    rm -f ${PID_FILE}
  else
    start
  fi

done


# EOF
