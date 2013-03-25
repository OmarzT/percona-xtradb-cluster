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

# CLEAN UP
find $DATADIR -name "*.tar.gz" -mtime +$RETENTION -print -exec rm -f {} \;

# BACKUP
echo "SHOW DATABASES;" | mysql -u $USER -h localhost -p$PASS | grep -v information_schema | while read DB; do
	mkdir -p $DATADIR/$DB
	mysqldump -x -u $USER -p$PASS $DB > $DATADIR/$DB/$FILENAME
	tar -czf $DATADIR/$DB/$FILENAME.tar.gz $DATADIR/$DB/$FILENAME
	chmod 600 $DATADIR/$DB/$FILENAME.tar.gz
done

exit 0

