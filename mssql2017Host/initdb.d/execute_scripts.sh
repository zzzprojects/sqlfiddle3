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

# Download the latest published version of Eval-SQL as part of the container startup
# Each version expires after a month, so it can't be saved statically within the container image
# The setup_script_template for SQL Server 2017 will execute it within each fiddle database
wget -q http://eval-sql.net/downloads/Eval-SQL.NET-Install.sql -O  /docker-entrypoint-initdb.d/scripts/03_Eval-SQL.NET-Install.sql
sed -i "s/USE \[DATABASE_NAME\]/USE \[master\]/" /docker-entrypoint-initdb.d/scripts/03_Eval-SQL.NET-Install.sql

for file in /docker-entrypoint-initdb.d/scripts/*.sql
do
    echo "Executing script ${file}"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d master -i ${file}
done

# Extract the latest assembly definitions into an external file, to be referenced in the creation of user fiddle databases:
/opt/mssql-tools/bin/bcp "SELECT content FROM sys.assembly_files WHERE name = 'Z.Expressions.Compiler'" \
    queryout /tmp/z_expressions_compiler.so -f /docker-entrypoint-initdb.d/bcp.fmt \
    -S localhost -U sa -P "${SA_PASSWORD}" -d master

/opt/mssql-tools/bin/bcp "SELECT content FROM sys.assembly_files WHERE name = 'Z.Expressions.SqlServer.Eval'" \
    queryout /tmp/z_expressions_sqlserver_eval.so -f /docker-entrypoint-initdb.d/bcp.fmt \
    -S localhost -U sa -P "${SA_PASSWORD}" -d master
