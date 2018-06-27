#Opts Search
##Searches for current optimizations in place
##By Nick DiLernia
##07/28/2013
##!/bin/bash
clear

optstype=$(whiptail --title "Optimization Search" --backtitle "Created by Nick DiLernia" --radiolist \
"Choose which opts to search for" 20 78 16 \
"Apache" "Check Apache" ON \
"FCGID" "Check FCGID" OFF \
"MySQL" "Check Mysql" OFF \
"PHP" "Check PHP" OFF )








if  [[ -z "$optstype"  ]]
 then
 echo "STATE1"
 whiptail --title "Optimization Search" --backtitle "Created by Nick DiLernia" --msgbox "No search criteria defined" 20 50
fi


#ApacheOptimizations


if [[ "$optstype" == Apache ]]
  then
  echo "STATE2"
  Apacheoptsclients=$(grep -i "MaxClients" /usr/local/apache/conf/httpd.conf)
  Apacheoptstimeout=$(grep -i "Timeout" /usr/local/apache/conf/httpd.conf | grep -iv "KeepAlive")
  Apacheoptsserver=$(grep -i "ServerLimit" /usr/local/apache/conf/httpd.conf)
  Apacheoptskeepaliveonoff=$(grep -i "KeepAlive" /usr/local/apache/conf/httpd.conf | grep -iv "Timeout" | grep -iv "Requests")
  Apacheoptskeepaliverequests=$(grep -i "MaxKeepAliveRequests" /usr/local/apache/conf/httpd.conf)
  Apacheoptskeepalivetime=$(grep -i "KeepAliveTimeout" /usr/local/apache/conf/httpd.conf)
  echo "Apache Optimizations" > /root/apacheopts.$(date +%Y%m%d).txt
  echo "--------------" >> /root/apacheopts.txt
  echo "$Apacheoptsclients" >> /root/apacheopts.txt
  echo "$Apacheoptstimeout" >> /root/apacheopts.txt
  echo "$Apacheoptsserver" >> /root/apacheopts.txt
  echo "$Apacheoptskeepaliveonoff" >> /root/apacheopts.txt
  echo "$Apacheoptskeepaliverequests" >> /root/apacheopts.txt
  echo "$Apacheoptkeepalivetime" >> /root/apacheopts.txt
  whiptail --textbox /root/apacheopts.$(date +%Y%m%d).txt 60 150
fi


if  [[ -z $optstype ]]

echo "STATE3"
  then
  exit
  fi