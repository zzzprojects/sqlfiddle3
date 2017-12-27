#!/bin/bash

/opt/mssql/bin/sqlservr &> /tmp/sqlservr.out &

tail -1000 /tmp/sqlservr.out

/docker-entrypoint-initdb.d/execute_scripts.sh

tail -f /tmp/sqlservr.out
