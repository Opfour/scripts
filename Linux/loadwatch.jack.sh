#!/bin/bash

#default settings
export LOADTHRESH=auto
export SQLTHRESH=25
export MEMTHRESH=80
export SWAPTHRESH=20
export APACHETHRESH=120
export APACHEPORT=80

date=$(date +%F.%X)
dir=/var/log/loadwatch
checklog=${dir}.log
file=${dir}/loadwatch.${date}

source /etc/default/loadwatch

# see /etc/loadwatch.conf for configuration

if [[ ${LOADTHRESH} -eq "auto" ]]
then
	LOADTHRESH=$(expr $(/bin/grep -c processor /proc/cpuinfo) / 2  + 7)
fi

local load=`cat /proc/loadavg | awk '{print $1}' | awk -F '.' '{print $1}'`

local mem
local swap
read mem swap <<<$(awk '{
	gsub(":$","",$1); m[$1] = $2
	} END {
		printf "%d ", ((m["MemTotal"]-m["MemFree"]-m["Buffers"]-m["Cached"])/m["MemTotal"])*100;
		printf "%d\n",((m["SwapTotal"]-m["SwapCached"]-m["SwapFree"])/m["SwapTotal"])*100;
	}' /proc/meminfo)

local cursql=$(/usr/bin/mysqladmin stat|awk '{print $4}')

local histsql=$(/usr/bin/mysql -Bse 'show global status LIKE "Max_used_connections";'|awk '{print $2}')

local apacheconn
if [[ -f /usr/local/cpanel/version ]] ; then
	apacheconn=$(/usr/bin/lynx -dump -width 400 localhost:${APACHEPORT}/whm-server-status |awk '/requests\ currently\ being\ processed,/ {print $1}')
else
	apacheconn=$(netstat -nt|awk 'BEGIN{n=0} $4 ~ /:(443|80|89)$/ { n++; } END { print n;}')
fi

printf "## %s load[%s] mem[%s/%s] mysql[%s/%s] httpd[%s/%s]\n" \
	${date} ${load} ${mem} ${swap} \
	${cursql} ${histsql} ${apacheconn} >> ${checklog}

if [ ${load} -gt ${LOADTHRESH} ] || \
	[ ${mem} -gt ${MEMTHRESH} ] || \
	[ ${swap} -gt ${SWAPTHRESH} ] || \
	[ ${cursql} -gt $SQLTHRESH ] || \
	[ ${apacheconn} -gt ${APACHETHRESH} ] ; then

	printf "## %s load[%s] mem[%s/%s] mysql[%s/%s] httpd[%s/%s]\n" \
		${date} ${load} ${mem} ${swap} \
		${cursql} ${histsql} ${apacheconn} >> ${checklog}

	printf "## server overview\n"
	printf "%s load[%s] mem[%s/%s] mysql[%s/%s] httpd[%s/%s]\n" \
		${date} ${load} ${mem} ${swap} \
		${cursql} ${histsql} ${apacheconn} >> ${file}
	free -m >> ${file}
	uptime >> ${file}

	printf "## system overview\n"
	top -bcn1 >> ${file}
	ps auxf >> ${file}

	printf "## mysql stats\n"
	mysqladmin processlist stat >> ${file}

	printf "## httpd stats\n"
	/bin/netstat -nut|awk '$4 ~ /:(80|443)/ {gsub(/:[0-9]*$/, "", $5); print $5, $6}'|sort|uniq -c|sort -n|tail -n50 >> ${file}
	if [[ -f /usr/local/cpanel/version ]] ; then
		/usr/bin/lynx -dump -width 400 localhost:${APACHEPORT}/whm-server-status >> ${file} 2>/dev/null
	else
		netstat -nt|awk 'BEGIN{n=0} $4 ~ /:(443|80|89)$/ { n++; } END { print n;}' >> ${file} 2>/dev/null
	fi

fi
