#!/bin/sh
mysql --skip-column-names -Be "SHOW DATABASES;" | grep -v 'lost+found' | while read database ; do
mysql --skip-column-names -Be "SHOW TABLE STATUS;" $database | while read name engine version rowformat rows avgrowlength datalength maxdatalength indexlength datafree autoincrement createtime updatetime checktime collation checksum createoptions comment ; do
  if [ "$datafree" -gt 0 ] ; then
   fragmentation=$(($datafree * 100 / $datalength))
   echo "$database.$name is $fragmentation% fragmented."
  fi
done
done

