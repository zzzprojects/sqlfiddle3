#!/bin/bash

psql -U postgres postgres -A -t -c "SELECT 'ready'"

export DATABASE_COUNT=`psql -U postgres postgres -A -t -c "select datname from pg_database where datname like 'db_%'" | wc -l`

echo "Found ${DATABASE_COUNT} PostgreSQL fiddle databases"

export CREATED_TIME=`stat -c "%Z" /proc/1/`
export CURRENT_TIME=`date +%s`
export UPTIME_SECONDS=`expr $CURRENT_TIME - $CREATED_TIME`
export UPTIME_MINUTES=`echo $(($UPTIME_SECONDS / 60))`
echo "Up for ${UPTIME_MINUTES} minutes"

if [ $DATABASE_COUNT -gt 50 ] || [ $UPTIME_MINUTES -gt 45 ]
then
  exit 1
else
  exit 0
fi
