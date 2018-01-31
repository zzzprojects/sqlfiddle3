#!/bin/bash

/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "SQLServerPassword!" \
    -d master -Q "SET NOCOUNT ON; SELECT 'ready'" -h -1

if [ "$?" -ne "0" ]
then
  exit 1
fi

export DATABASE_COUNT=`/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "SQLServerPassword!" -d master -Q "SET NOCOUNT ON; SELECT name FROM master..sysdatabases where name like 'db_%'" -h -1 | wc -l`

echo "Found ${DATABASE_COUNT} MS SQL fiddle databases"

if [ $DATABASE_COUNT -gt 25 ]
then
  exit 1
else
  exit 0
fi
