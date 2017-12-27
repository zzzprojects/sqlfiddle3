FROM microsoft/mssql-server-linux:2017-CU2

ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=SQLServerPassword!
ENV MSSQL_PID=Express

COPY initdb.d /docker-entrypoint-initdb.d

CMD /bin/bash /docker-entrypoint-initdb.d/entrypoint.sh
