#!/bin/bash
# Needed : mysql -e "CREATE USER 'perconha'@'localhost' IDENTIFIED BY 'secret'; FLUSH PRIVILEGES;"

MYSQLHOST='localhost'
MYSQLPORT='3306'
MYSQLUSER='perconha'
MYSQLPASS='secret'

VIPRO='127.0.0.2/32'
VIPRW='127.0.0.3/32'

ETH='eth1'

novip() {
	ifconfig $1 $2 down &> /dev/null
}

vip() {
	if [ -e '/etc/perconHa/RW' ]; then
		ifconfig $ETH:1 $VIPRW
	else
		novip $ETH:1 $VIPRW
	fi
	if [ -e '/etc/perconHa/RO' ]; then
		ifconfig $ETH:2 $VIPRO
	else
		novip $ETH:2 $VIPRO
	fi
}

# is MySQL running ?
if [ `ps aux | grep mysqld | wc -l` -eq 0 ]; then
	# DEAD
	exit 1
fi

# is in cluster ?
if [ `mysql --force -h $MYSQLHOST -P $MYSQLPORT -u $MYSQLUSER -p$MYSQLPASS -B -N -e "SHOW STATUS WHERE Variable!name = 'wsrep_ready';" | awk '{ print $2 }'` = "ON" ]; then
	# is synced ?
	if [ `mysql --force -h $MYSQLHOST -P $MYSQLPORT -u $MYSQLUSERNAME -p$MYSQLPASSW -B -N -e "SHOW STATUS WHERE Variable_name = 'wsrep_local_state_comment';" | awk '{print $2}'` = "Synced" ]; then
		# SYNCED
		vip
		exit 0
	else
		# NOT SYNCED
		novip $ETH:1 $VIPRW
		novip $ETH:2 $VIPRO
		exit 1
	fi
else
	# NOT IN CLUSTER
	novip $ETH:1 $VIPRW
	novip $ETH:2 $VIPRO
	exit 1
fi

exit 0
