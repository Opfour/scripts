#!/bin/bash
##############################################################################
# sysbench-loom.sh
# 2011-10 by Nick Hope
#
# Iteratively runs sysbench oltp tests for THREAD_START to THREAD_MAX threads 
##############################################################################

### Test Variables ###
#table size defines the number of rows to create
TABLE_SIZE=500000
#specified in seconds
RUN_TIME=600
THREAD_START=1
THREAD_MAX=32
THREAD_ITERATIONS=3

### MySQL Settings ###
MYSQL_HOST="localhost"
MYSQL_PORT="3306"

### Where to save? ###
RESULTS_DIR=/root/oltp-results
MYSQL_VERSION=`rpm -qa | grep -i "percona-server-server\|mysql-server"`
#MYSQL_VERSION="hardcoded"

################
# Script start #
################

for thread_count in `seq $THREAD_START $THREAD_MAX`
do
    for iteration_count in `seq 1 $THREAD_ITERATIONS`
    do
        echo $thread_count - $iteration_count
        ###
        #Prepare database/users
        if [ ! -d $RESULTS_DIR ]; then mkdir -p $RESULTS_DIR; fi
        mysql -e "create database sbtest"
        mysql -e "create user 'sbtest'@'%' identified by 'sbpass'"
        mysql -e "create user 'sbtest'@'localhost' identified by 'sbpass'"
        mysql -e "grant all on sbtest.* to 'sbtest'@'%'"
        mysql -e "grant all on sbtest.* to 'sbtest'@'localhost'"

        sysbench --test=oltp --mysql-user=sbtest --mysql-password=sbpass --mysql-host=$MYSQL_HOST --mysql-port=$MYSQL_PORT --oltp-table-size=$TABLE_SIZE --mysql-table-engine=innodb prepare

        ###
        #Run oltp test
        DATE=`date +%Y%m%d_%H%M%S`
        sysbench --test=oltp --oltp-test-mode=complex --mysql-user=sbtest --mysql-password=sbpass --mysql-host=$MYSQL_HOST --mysql-port=$MYSQL_PORT --mysql-table-engine=innodb --max-requests=0 --num-threads=$thread_count --max-time=$RUN_TIME run > $RESULTS_DIR/$MYSQL_VERSION.$DATE-threads-$thread_count.$iteration_count

        ###
        #Cleanup database/users
        mysql -e "drop user 'sbtest'@'%'"
        mysql -e "drop user 'sbtest'@'localhost'"
        mysql -e "drop database sbtest"
    done
done
