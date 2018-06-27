#!/bin/bash

sIP=($(ip a|egrep -o "inet\ ([0-9]{1,3}\.){3}[0-9]{1,3}"|awk '{print$2}'));

getInfo() {
    sed -r "s/^(.*+)\: ([^=]+)=+[^=]+=+([^=]+)=+[^=]+=+([^=]+)=+.*$/\1 \2/g" /etc/userdatadomains|while read domain user; do
        if [[ -z $option || "$option" == "A" ]]; then
            IP=($(dig ${domain} $option @8.8.8.8 +short));
        else
            if [[ "$option" == "MX" ]]; then
                RECORDS=($(dig ${domain} $option @8.8.8.8 +short|awk '{print$NF}'));
            else
                RECORDS=($(dig ${domain} $option @8.8.8.8 +short));
            fi
        fi
        if [[ -z "${RECORDS[*]}" ]]; then
            if [[ -z "${IP[*]}" ]]; then
                echo "$user $domain None";
            else
                for ip in ${!IP[@]}; do
                    if [[ $(echo ${sIP[*]}|grep ${IP[$ip]}) ]]; then
                        where='local';
                    else
                        where='remote';
                    fi
                    if [[ $ip -lt 1 ]]; then
                        echo "$user $domain ${IP[$ip]} $where";
                    else
                        echo -e "  ${IP[$ip]} $where";
                    fi;
                done;
            fi;
        else
            for record in ${!RECORDS[@]}; do
                IP=($(dig ${RECORDS[$record]} @8.8.8.8 +short));
                if [[ -z "${IP[*]}" ]]; then
                    echo "$user $domain ${RECORDS[$record]} None";
                else
                    for ip in ${!IP[@]}; do
                        if [[ $(echo ${sIP[*]}|grep ${IP[$ip]}) ]]; then
                            where='local';
                        else
                            where='remote';
                        fi
                        if [[ $record -lt 1 ]]; then
                            if [[ $ip -lt 1 ]]; then
                                echo "$user $domain ${RECORDS[$record]} ${IP[$ip]} $where";
                            else
                                echo "   ${IP[$ip]} $where";
                            fi;
                        else
                            echo "  ${RECORDS[$record]} ${IP[$ip]} $where";
                        fi;
                    done;
                fi;
            done;
        fi;
    unset IP && unset RECORDS;
    done;
};

(option=${1^^}; if [[ -z $option || "$option" == "A" ]]; then echo "User Domain Record Where"; elif [[ "$option" != "TXT" && "$option" != "MX" && "$option" != "A" && "$option" != "NS" ]]; then echo -e "Sorry, this script doesn't support ${option} lookups\n"; exit; else echo "User Domain Record IP Where"; fi;
getInfo ${1})|column -ts" "

