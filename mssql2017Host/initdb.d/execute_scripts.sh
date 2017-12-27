#!/bin/bash

while true
do
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d master -Q "SELECT 1" &> /dev/null
    if [ $? = 0 ];
     then
        echo  'SQL Server ready'
        break
     fi
    echo 'Waiting for SQL Server to become ready...'
    sleep 1
done

for file in /docker-entrypoint-initdb.d/scripts/*.sql
do
    echo "Executing script ${file}"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d master -i ${file} &
done
