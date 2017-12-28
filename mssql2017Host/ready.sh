#!/bin/sh

/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "SQLServerPassword!" \
    -d master -Q "SET NOCOUNT ON; SELECT 'ready'" -h -1
