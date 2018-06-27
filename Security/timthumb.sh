#/bin/bash
wget -O /usr/local/src/thumb.php http://timthumb.googlecode.com/svn/trunk/timthumb.php
if [ ! -e /usr/local/src/thumb.php ]
then
  echo 'unable to fetch current timthumb script (http://timthumb.googlecode.com/svn/trunk/timthumb.php), exiting'
else
  echo 'locating timthumb scripts'
  find /home/*/public_html/ -type f -name "*thumb.php" > /usr/local/src/list
  sed '/ /d' /usr/local/src/list > /usr/local/src/list2
  for each in `cat /usr/local/src/list2` ; do grep -Hi timthumb $each ; done | cut -d':' -f 1 | sort | uniq > /usr/local/src/list3
  echo 'backing up and updating the located scripts'
  for each in `cat /usr/local/src/list3` ; do cp $each $each.bak && chmod 000 $each.bak ; done
  for each in `cat /usr/local/src/list3` ; do cat /usr/local/src/thumb.php > $each ; done
  echo 'done, cleaning up'
  rm -f /usr/local/src/list
  rm -f /usr/local/src/list2
  rm -f /usr/local/src/thumb.php
  echo 'The following files were replaced (If there is no output, timthumb was not found)' && cat /usr/local/src/list3
  rm -f /usr/local/src/list3
fi
