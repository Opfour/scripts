#!/bin/bash
#test.sh
#https://hd.int.liquidweb.com/msgs/index.mhtml?id=2908094#103
#usage: sh test.sh domain.com

#old script below
#while true; do
#  echo "$(date) $(((curl -sqI ${1}) && echo || echo "Error: $?") | head -1)"
#  sleep 30
#done

while true; do
  echo "$(date) $( ( curl -sqI ${1} && echo || echo "Error: $?" ) | head -1)"
  sleep 30
done 

