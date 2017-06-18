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
s3cmd --no-progress --force put sqlfiddle.sql.gz s3://${S3_BUCKET}/sqlfiddle.sql-tmp.gz
s3cmd --no-progress --force cp s3://${S3_BUCKET}/sqlfiddle.sql-tmp.gz s3://${S3_BUCKET}/sqlfiddle.sql.gz
s3cmd --no-progress --force del s3://${S3_BUCKET}/sqlfiddle.sql-tmp.gz

EOF
#########################################

    chmod +x ~/backup.sh

    # run backups every day at 2am server time
    echo "0 2 * * *       /root/backup.sh >> /root/backup.out 2>&1" | crontab

fi
