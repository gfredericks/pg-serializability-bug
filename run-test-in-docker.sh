#!/bin/bash

if [ -z ${INSIDE_CONTAINER+x} ]
then
  # Not in the container
  PWD=`pwd`
  CONTAINER_ID=`docker run --env='INSIDE_CONTAINER=1' -p 15432:5432 --name=pg-serializability-bug -w /volume -d -v "$PWD":/volume postgres:9.4`

  trap "docker rm -f $CONTAINER_ID" EXIT HUP INT QUIT PIPE TERM

  docker exec $CONTAINER_ID ./run-test-in-docker.sh

else

  # In the container

  function is_db_up {
    echo "SELECT 1" | psql postgres postgres 1>/dev/null 2>/dev/null
  }

  echo -n "Waiting for db to be up..."
  until is_db_up ; do
    printf '.'
    sleep 1
  done
  echo done\!


  ./run-test.sh
fi
