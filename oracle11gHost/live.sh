#!/bin/bash

export STATUS=`su -p oracle -c "echo \"SELECT CASE WHEN count(*) < 50 THEN 'REA'||'DY' ELSE 'OVERCAPACITY' END as status FROM (select distinct lower(replace(USERNAME, 'USER', 'DB')) as schema_name from all_users) tmp WHERE schema_name LIKE 'db_%';\" | sqlplus system/password as sysdba" | grep READY`

if [ $STATUS = "READY" ]
then
  exit 0
else
  sleep 60
  exit 1
fi
