FROM postgres:9.3

ENV POSTGRES_PASSWORD password
ENV POSTGRES_DB postgres

COPY initdb.d /docker-entrypoint-initdb.d

RUN apt-get -qq update
RUN apt-get -qq -y install curl
