# Postgres Serializability Bug

The follow applies to at least postgres 9.3, 9.4, and 9.5.

To reproduce, run `./run-test.sh` if you have a postgres running on
localhost; you can set the `PG_USER` and `PG_DB` env variables as
appropriate (they both default to `postgres`).

Alternatively, you can run `./run-test-in-docker.sh` if you have
docker installed.

## The Scenario

Say you have a `CREATE TABLE things (id VARCHAR(1) PRIMARY KEY)`.

Then you run the following two transactions (which differ only in the
`id` that they `INSERT`) in parallel:

``` sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO things (id) VALUES ('A');
SELECT id FROM things;
COMMIT;
```

``` sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO things (id) VALUES ('B');
SELECT id FROM things;
COMMIT;
```

Each one should be retried until it succeeds. What should the
`SELECT`ed results from the two eventually-successful queries be?

Since we're using the serializable isolation level, I assume the
results ought to be either of the two possibilities that we would see
from running the two transactions one at a time. I.e., either process
A sees `[A]` and process B sees `[A, B]`, or process A sees `[B, A]` and
process B sees `[B]` (ignoring possible ordering differences).

This is the result we see ~99% of the time, but occasionally we will
see that A sees `[A]` and B sees `[B]`, even though both transactions
succeed.

## Modifications

I've also tried this with an `INSERT` into a logging table after the
`SELECT`, containing the results of the `SELECT`, just to ensure that
the actual state of the database at the end of the run is one that is
impossable to reach via serialized transactions, and this also happens
occasionally.
