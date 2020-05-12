#!/bin/bash

mysql -u root -ppassword mysql -ss -e "SELECT 'ready'"

export DATABASE_COUNT=`mysql -u root -ppassword mysql -e "show databases like 'db_%'" -ss | wc -l`

echo "Found ${DATABASE_COUNT} MySQL fiddle databases"

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
