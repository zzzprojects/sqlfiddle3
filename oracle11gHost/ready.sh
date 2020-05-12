#!/bin/bash

STATUS=`su -p oracle -c "echo \"SELECT CASE WHEN count(*) > 0 THEN 'REA'||'DY' ELSE 'STARTING' END as status FROM dba_tablespaces WHERE tablespace_name = 'FIDDLEDATA';\" | sqlplus system/password as sysdba" | grep READY`

if [ "$STATUS" != "READY" ]
then
  echo "Not started yet"
  exit 1
fi


CAPACITY=`su -p oracle -c "echo \"SELECT CASE WHEN count(*) < 50 THEN 'REA'||'DY' ELSE 'OVERCAPACITY' END as status FROM (select distinct lower(replace(USERNAME, 'USER', 'DB')) as schema_name from all_users) tmp WHERE schema_name LIKE 'db_%';\" | sqlplus system/password as sysdba" | grep READY`

export CREATED_TIME=`stat -c "%Z" /proc/1/`
export CURRENT_TIME=`date +%s`
export UPTIME_SECONDS=`expr $CURRENT_TIME - $CREATED_TIME`
export UPTIME_MINUTES=`echo $(($UPTIME_SECONDS / 60))`
echo "Up for ${UPTIME_MINUTES} minutes"

if [ "$CAPACITY" != "READY" ] || [ $UPTIME_MINUTES -gt 45 ]
then
  echo "Overcapacity"
  exit 1
fi

exit 0
