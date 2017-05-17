FROM mysql:5.6

ENV MYSQL_ROOT_PASSWORD password

COPY my.cnf /etc/mysql/conf.d/my.cnf

RUN apt-get -qq update
RUN apt-get -qq -y install curl

COPY initdb.d /docker-entrypoint-initdb.d

CMD ["mysqld"]
