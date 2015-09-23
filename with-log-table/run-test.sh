 #!/bin/bash

#
# Assumes there's a postgres running on localhost:5432,
# connectable with username & dbname 'postgres', no
# password.
#

export PG_USER=${PG_USER:-postgres}
export PG_DB=${PG_DB:-postgres}


psql -f create-schema.sql $PG_DB $PG_USER

for i in `seq 1 2000`;
do
  psql -f prep.sql $PG_DB $PG_USER 2>&1 > /dev/null

  ./retry-loop.sh A &
  PID_A=$!

  ./retry-loop.sh B &
  PID_B=$!

  wait $PID_A
  wait $PID_B

  RES=`echo "SELECT string_agg(msg,',') FROM log" | psql -qt $PG_DB $PG_USER | tr -d ' \n'`

  echo "$i: $RES"

  if !([ "$RES" = "A,AB" ] || [ "$RES" = "BA,B" ] || [ "$RES" = "B,BA" ])
  then
    echo "Found a failure!"
    echo 'SELECT * FROM log:'
    echo 'SELECT * FROM log;' | psql $PG_DB $PG_USER
    break
  fi

done
