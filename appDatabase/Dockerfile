FROM postgres:9.6

ENV POSTGRES_PASSWORD password
ENV POSTGRES_DB sqlfiddle

COPY initdb.d /docker-entrypoint-initdb.d
