#!/bin/bash

#
# Assumes there's a postgres running on localhost:5432,
# connectable with username & dbname 'postgres', no
# password.
#

export PG_USER=${PG_USER:-postgres}
export PG_DB=${PG_DB:-postgres}
export PG_HOST=${PG_HOST:-localhost}
export PG_PORT=${PG_PORT:-5432}


psql -f create-schema.sql $PG_DB $PG_USER

for i in `seq 1 2000`;
do
  psql -h $PG_HOST -p $PG_PORT -f prep.sql $PG_DB $PG_USER 2>&1 > /dev/null

  ./retry-loop.sh A &
  PID_A=$!

  ./retry-loop.sh B &
  PID_B=$!

  wait $PID_A
  wait $PID_B

  A_RESULT=`tr -d ' \n' < A.log`
  B_RESULT=`tr -d ' \n' < B.log`

  RES="$A_RESULT,$B_RESULT"

  echo "$i: $RES"

  if !([ "$RES" = "A,AB" ] || [ "$RES" = "BA,B" ])
  then
    echo "Found a failure!"
    break
  fi

done
