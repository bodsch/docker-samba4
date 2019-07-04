#!/bin/bash

CURL=$(which curl 2> /dev/null)
NC=$(which nc 2> /dev/null)
NC_OPTS="-z"

if [[ -z "${NC}" ]]
then
  NC=$(which nc 2> /dev/null)
  NC_OPTS=
fi


inspect() {

  echo ""
  echo "inspect needed containers"
  for d in $(docker ps | tail -n +2 | awk  '{print($1)}')
  do
    # docker inspect --format "{{lower .Name}}" ${d}
    c=$(docker inspect --format '{{with .State}} {{$.Name}} has pid {{.Pid}} {{end}}' ${d})
    s=$(docker inspect --format '{{json .State.Health }}' ${d} | jq --raw-output .Status)

    printf "%-40s - %s\n"  "${c}" "${s}"
  done
  echo ""
}


wait_for_samba() {

  echo "wait for healthy samba4"

  RETRY=40
  until [[ ${RETRY} -le 0 ]]
  do
    d=$(docker ps | tail -n +2 | egrep samba4 | awk '{print($1)}')

    s=$(docker inspect --format '{{json .State.Health }}' ${d} | jq --raw-output .Status)

    # echo "'${s}'"

    if [[ "${s}" = "healthy" ]]
    then
      break
    elif [[ "${s}" = "unhealthy" ]]
    then
      docker logs --details ${d}

      exit 1
    else
      sleep 5s
      RETRY=$(expr ${RETRY} - 1)
    fi
  done

  if [[ $RETRY -le 0 ]]
  then
    echo "could not found an healthy samba4"

    inspect

    exit 1
  fi
  echo ""
}


check_samba4() {

  network=$(docker network ls | egrep "*samba4*" | awk '{print $2}')

  docker run \
    --link samba4 \
    --network ${network} \
    ${USER}/${DOCKER_IMAGE_NAME}-client
}

running_containers=$(docker ps | tail -n +2 | egrep -c samba4)

if [[ $(docker ps | tail -n +2 | egrep -c samba4) -eq 1 ]]
then

  inspect

  wait_for_samba

  check_samba4

  exit 0
else
  echo "no running samba4 container found"
  echo "please run 'make compose-file' and 'docker-compose up --build -d' before"

  exit 1
fi

exit 0
