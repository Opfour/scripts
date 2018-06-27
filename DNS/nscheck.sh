

#!/bin/bash

#### License: GPLv3, see LICENSE file for details

#### First: cat  /etc/userdatadomains | awk '{print $1}' | tr -d ':|*' > domainlist.txt

#### CONFIG - begin ####
# Nameserver to query?
QUERY_NAMESERVER="8.8.8.8"

# What to check
CHECK_SOA=1
CHECK_NAMESERVERS=1

# Delay between each query in seconds (can be 0.x too)
QUERY_DELAY="1"

# Column widths
WIDTH_DOMAIN=67        # IPv6 reverse entries are 64 characters long
WIDTH_NAMESERVERS=25

# Show headers?
SHOW_HEADERS=1
#### CONFIG - end ####


# Check attributes
if [ "$1" == "" ]; then
  echo "USAGE: $0 <File with list of domains>"
  echo "       (One domain each line)"
  exit 1
fi

INPUT_FILE=$1

if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: File \"$INPUT_FILE\" does not exist!"
  exit 1
fi


# Show headers
if [ $SHOW_HEADERS -eq 1 ]; then
  printf "%-${WIDTH_DOMAIN}s" "Domain"
  if [ $CHECK_SOA -eq 1 ]; then
    printf "%-${WIDTH_NAMESERVERS}s" "SOA"
  fi
  if [ $CHECK_NAMESERVERS -eq 1 ]; then
    printf "%-${WIDTH_NAMESERVERS}s" "Nameservers"
  fi
  printf "\n"
fi


# Loop through each line in given file
while read DOMAIN
do
  # Get query answer
  QUERY_RESULT=`dig @$QUERY_NAMESERVER $DOMAIN any`

  RESULT=$(printf "%-${WIDTH_DOMAIN}s" $DOMAIN)

  # Get SOA record
  if [ $CHECK_SOA -eq 1 ]; then
    SOA_NAMESERVER=`echo "$QUERY_RESULT" | grep -i "\sSOA\s" | tail -1 | sed -E 's/[[:space:]]+/ /g' | cut -d' ' -f5 | sed 's/.$//'`
    RESULT="${RESULT}$(printf "%-${WIDTH_NAMESERVERS}s" $SOA_NAMESERVER)"
  fi

  # Get NS record(s)
  if [ $CHECK_NAMESERVERS -eq 1 ]; then
    NAMESERVERS=`echo "$QUERY_RESULT" | grep -i "\sNS\s" | sed -E 's/[[:space:]]+/ /g' | cut -d' ' -f5 | sed 's/.$//' | sort`

    while read -r NAMESERVER; do
      RESULT="${RESULT}$(printf "%-${WIDTH_NAMESERVERS}s" $NAMESERVER)"
    done <<< "$NAMESERVERS"
  fi

  # Remove trailing whitespaces and output result
  RESULT=`echo "$RESULT" | sed -E 's/[[:space:]]*$//'`
  echo "$RESULT"

  # Delay next query
  sleep $QUERY_DELAY
done < $INPUT_FILE
