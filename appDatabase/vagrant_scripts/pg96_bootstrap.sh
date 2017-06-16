#!/bin/bash

# create a 512mb swapfile
dd if=/dev/zero of=/swapfile1 bs=1024 count=524288
chown root:root /swapfile1
chmod 0600 /swapfile1
mkswap /swapfile1
swapon /swapfile1
echo "/swapfile1 none swap sw 0 0" >> /etc/fstab

export LANGUAGE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get -qq --yes update
apt-get -qq --yes upgrade
apt-get -qq --yes --force-yes install postgresql-9.6 postgresql-contrib-9.6

pg_dropcluster --stop 9.6 main
echo "listen_addresses = '*'" >> /etc/postgresql-common/createcluster.conf
echo "max_connections = 500" >> /etc/postgresql-common/createcluster.conf
pg_createcluster --start -e UTF-8 --locale en_US.UTF-8 9.6 main -- --auth-local=trust
echo "host    all             all             10.1.0.0/16            md5" >> /etc/postgresql/9.6/main/pg_hba.conf
service postgresql reload

echo "alter user postgres with password 'password';" | psql -U postgres
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT


createdb -U postgres -E UTF8 sqlfiddle
psql -U postgres sqlfiddle < /vagrant/initdb.d/01_schema.sql
psql -U postgres sqlfiddle < /vagrant/initdb.d/02_data.sql
