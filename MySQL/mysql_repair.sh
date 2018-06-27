#!/bin/bash
for db in `mysql -s -B -e "show databases"`;
do
       for table in `mysql $db -s -B -e "show tables"`;
       do
               mysql $db -e "repair table $table";
       done
done


