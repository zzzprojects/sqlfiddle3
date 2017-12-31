#!/bin/bash

mysql -u root -ppassword mysql -ss -e "SELECT 'ready'"

export DATABASE_COUNT=`mysql -u root -ppassword mysql -e "show databases like 'db_%'" -ss | wc -l`

echo "Found ${DATABASE_COUNT} MySQL fiddle databases"

if [ $DATABASE_COUNT -gt 50 ]
then
  exit 1
else
  exit 0
fi
