ID=$1

function tryit {
  psql -h $PG_HOST -v ON_ERROR_STOP=1 -qt -f run-$ID.sql $PG_DB $PG_USER > $ID.log 2>/dev/null
}

until tryit ; do
  noop="foo"
done
