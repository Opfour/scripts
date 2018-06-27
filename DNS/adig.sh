#!/bin/bash
#Script to query common records from several different sources (NS / Resolv.conf / Google / Domain's name servers). Makes it easy to check differences between servers. Also colorizes results for easier viewing.

OIFS=$IFS;IFS=$'\n' 

function printresults {
        #$1 Title
        #$2 Message
        echo -e "\e[01;32m=== $1 ===\e[0m"
        for r in $(echo "$2")
        do
                echo -e "`colorresult $r`"
        done
}

function colorresult {
        rtype=`echo "$1" | awk '{print $4}'`
        case $rtype in
                A)
                        echo "\e[0;32m`echo "$1"`\e[0m"
                        ;;
                MX)
                        echo "\e[0;31m`echo "$1"`\e[0m"
                        ;;
                TXT)
                        echo "\e[0;34m`echo "$1"`\e[0m"
                        ;;
                NS)
                        echo "\e[0;36m`echo "$1"`\e[0m"
                        ;;
                CNAME)
                        echo "\e[0;35m`echo "$1"`\e[0m"
                        ;;
                *)
                        echo "$1"
                        ;;
        esac
}

function getdig {
        #$1 domain
        #$2 against
        if [ -n "$2" ]
        then
                digresult=`dig $1 ANY +noall +answer @$2`
        else
                digresult=`dig $1 ANY +noall +answer`
        fi
        cleaned=`echo "$digresult" | grep -v "<<>>" | grep -ve "^;;" | sed "/^$/d" | sort -k 4`
        echo "$cleaned"
}

diglw=`getdig $1 "ns.liquidweb.com"`
diggoogle=`getdig $1 "8.8.8.8"`
dignorm=`getdig $1`

tld=`echo $1 | rev | cut -d'.' -f1,2 | rev`
digns=`dig $tld NS +short`

printresults "Default dig results" "$dignorm"
printresults "Liquid Web dig results" "$diglw"
printresults "Google dig results" "$diggoogle"

for i in $(echo "$digns")
do
        digresult=`getdig $1 $i`
        printresults "Digging against $i" "$digresult"
done

IFS=$OIFS
