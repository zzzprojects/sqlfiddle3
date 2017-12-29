#!/bin/bash

export STATUS=`su -p oracle -c "echo \"SELECT CASE WHEN count(*) > 0 THEN 'REA'||'DY' ELSE 'STARTING' END as status FROM dba_tablespaces WHERE tablespace_name = 'FIDDLEDATA';\" | sqlplus system/password as sysdba" | grep READY`

if [ $STATUS = "READY" ]
then
  exit 0
else
  exit 1
fi
