#!/bin/bash
# GRANT SELECT, LOCK TABLES, SHOW DATABASES ON *.* TO dump@localhost;
# FLUSH privileges;

PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
USER='dump'
PASS='secret'
RETENTION=7
DATADIR='/backup'
DATE=`date '+%Y%m%d'`
FILENAME="$DATE.sql"
BWLIMIT=2 # KBps

if [ ! -f /etc/perconHa/BCK ]; then
	exit 1
fi

# CLEAN UP
find $DATADIR -name "*.tar.gz" -mtime +$RETENTION -print -exec rm -f {} \;

# BACKUP
echo "SHOW DATABASES;" | mysql -u $USER -h localhost -p$PASS | grep -v information_schema | while read DB; do
	mkdir -p $DATADIR/$DB
	mysqldump -x -u $USER -p$PASS $DB > $DATADIR/$DB/$FILENAME
	tar -czf $DATADIR/$DB/$FILENAME.tar .gz $DATADIR/$DB/$FILENAME
	chmod 600 $DATADIR/$DB/$FILENAME.tar.gz
done

for ip in `mysql -h localhost -u $USER -p $PASS -B -N -e "SHOW STATUS WHERE Variable_name = 'wsrep_incoming_address';" | awk '{ print $2 }' | sed 's/:3306/\n/g' | sed 's/,//g' | grep -v "^$"`; do
	ip a | grep $ip &> /dev/null
	if [ $? -eq 0 ]; then
		continue
	fi
	rsync -a --del --bwlimit=$BWLIMIT /backup/* $ip:/backup/ &> /dev/null
done

exit 0

