#!/bin/bash

blue='\e[1;96m'
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
purple='\e[1;35m'
reset='\e[0m'

if [[ ! -d /home/lwtemp ]]; then
    mkdir /home/lwtemp && printf "${yellow}Created working space: /home/lwtemp${reset}\n\n"
else
    printf "${green}Working space already exists at /home/lwtemp${reset}\n\n"
fi

notFound=""
found=""
service=""
cvePath=""

while [[ ${service} == "" || ${valid} == 0 ]]; do
    printf "What service would you like to check?\n1) openssl\n2) openssh\n3) bind\nOr enter your own service: "
    read service
    if [[ ${service} == 1 ]]; then
        service="openssl"
        valid=1
    elif [[ ${service} == 2 ]]; then
        service="openssh"
        valid=1
    elif [[ ${service} == 3 ]]; then
        service="bind"
        valid=1
    fi
    if [[ $(rpm -q ${service}|egrep -v "not installed$") ]]; then
        valid=1
        changeLog="/home/lwtemp/pci_${service}.changelog"
        rpm -q ${service} --changelog > $changeLog
    else
        printf "\n${red}${service} is not a valid package.${reset}\n\n"
        valid=0
    fi
done

while [[ ! -f ${cvePath} || -z $(egrep -io "CVE(\-[0-9]{4}){2}" ${cvePath}) ]]; do
#   printf "What is the path to the ${service} CVE list? "
    printf "Where are the CVE's to check? "
    read cvePath
    if [[ ! -f ${cvePath} ]]; then
        printf "${red}${cvePath} is not a valid file.${reset}\n\n"
    elif [[ -z $(egrep -io "CVE(\-[0-9]{4}){2}" ${cvePath}) ]]; then
        printf "${red}${cvePath} doesn't contain a valid CVE listing.${reset}\n\n"
    fi
done

#for cve in $(cat ${cvePath}); do
for cve in $(egrep -io "CVE(\-[0-9]{4,5}){2}" ${cvePath}); do
    if [[ -z $(grep -i ${cve} ${changeLog}) ]]; then
        notFound="${notFound} ${cve}"
    else
        found="${found} ${cve}"
    fi
done

printf "\n${blue}Checking: ${service}\nwith CVE list at: ${cvePath}${reset}\n"

printf "\n${service} CVE's not found in changelog:\n${red}"
for i in ${notFound}; do
   printf "${i} - https://access.redhat.com/security/cve/${i}\n"
done

printf "${reset}\n${service} CVE's found in changelog:\n${green}"
for i in ${found}; do
   echo "$(grep -i ${i} ${changeLog})"
done

printf "${reset}"
