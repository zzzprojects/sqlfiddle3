#!/bin/bash

if [ -e "/vagrant/vagrant_scripts/.s3cfg" ]
then
    apt-get --yes --force-yes install s3cmd

    chmod 600 /vagrant/vagrant_scripts/.s3cfg
    cp /vagrant/vagrant_scripts/.s3cfg ~


#########################################
cat << EOF > ~/backup.sh

# nice -n 19 makes these backups be as low priority as possible, so as to not interfere as much with the DB process
nice -n 19 pg_dump -U postgres sqlfiddle | nice -n 19 gzip > sqlfiddle.sql.gz
s3cmd --no-progress --force put sqlfiddle.sql.gz s3://sqlfiddle/sqlfiddle.sql-tmp.gz
s3cmd --no-progress --force cp s3://sqlfiddle/sqlfiddle.sql-tmp.gz s3://sqlfiddle/sqlfiddle.sql.gz
s3cmd --no-progress --force del s3://sqlfiddle/sqlfiddle.sql-tmp.gz

EOF
#########################################

    chmod +x ~/backup.sh

    # run backups every day at 2am server time
    echo "0 2 * * *       /root/backup.sh >> /root/backup.out 2>&1" | crontab

    # restore from backup if there is a backup available
    s3cmd get s3://sqlfiddle/sqlfiddle.sql.gz
    if [ -e "/root/sqlfiddle.sql.gz" ]
    then
        dropdb -U postgres sqlfiddle
        createdb -U postgres -E UTF8 sqlfiddle
        gunzip -c sqlfiddle.sql.gz | psql -U postgres sqlfiddle
        # cannot assume that the hosts which were available at the last backup are still available
        echo "UPDATE shema_defs SET current_host_id = null;" | psql -U postgres sqlfiddle
        echo "DELETE FROM hosts;" | psql -U postgres sqlfiddle
    fi

fi
