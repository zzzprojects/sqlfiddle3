#!/bin/bash

psql -U postgres postgres -A -t -c "SELECT 'ready'"

export DATABASE_COUNT=`psql -U postgres postgres -A -t -c "select datname from pg_database where datname like 'db_%'" | wc -l`

echo "Found ${DATABASE_COUNT} PostgreSQL fiddle databases"

if [ $DATABASE_COUNT -gt 50 ]
then
  exit 1
else
  exit 0
fi
