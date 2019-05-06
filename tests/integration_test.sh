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
}


check_samba4() {

  network=$(docker network ls | egrep "*samba4*" | awk '{print $2}')

  docker run \
    --link samba4 \
    --network ${network} \
    ${USER}/${DOCKER_IMAGE_NAME}-client
}



running_containers=$(docker ps | tail -n +2  | wc -l)

if [[ ${running_containers} -eq 1 ]] || [[ ${running_containers} -gt 1 ]]
then

  inspect

  check_samba4

  exit 0
else
  echo "please run "
  echo " make start"
  echo "before"

  exit 1
fi

exit 0
