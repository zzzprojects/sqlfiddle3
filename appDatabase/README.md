When doing development locally, connect to the running db instance like so:

    docker-compose exec appDatabase psql -U postgres sqlfiddle

Save the changes made to a running database with this command:

    docker-compose exec appDatabase pg_dump \
        --inserts --data-only -t db_types -t schema_defs -t queries \
         -U postgres sqlfiddle -f /tmp/02_data.sql

    docker cp sqlfiddle3_appDatabase_1:/tmp/02_data.sql appDatabase/initdb.d

    docker-compose exec appDatabase pg_dump \
         --inserts --data-only -t hosts \
          -U postgres sqlfiddle -f /tmp/03_samplehosts.sql

    docker cp sqlfiddle3_appDatabase_1:/tmp/03_data.sql appDatabase/initdb.d
