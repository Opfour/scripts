#!/bin/bash
LOGFILE=/var/log/exim_mainlog
LOCAL_DOMAINS=`cat /etc/localdomains | sed  's/^/for .*@/g' | tr '\n' '|' | sed 's/|$//'`
NUM_RCPTS=15
check_for_scripts()
{
    SCRIPTED_EMAILS=`cat $LOGFILE | grep cwd= |  grep -v spool | cut -d' ' -f4 | sort | uniq -c | sort -rn | head`
}

check_for_auth()
{
    AUTH_EMAILS=`cat $LOGFILE | grep -o "A\=fixed_.*:[[:alnum:][:graph:]]*@[[:alnum:][:graph:]]*" | cut -d: -f2`
}

check_most_sent()
{
    MOST_SENT_DOMAIN=`cat $LOGFILE | grep '<=' | grep -v mailnull | egrep -v "$LOCAL_DOMAINS" | cut -d" " -f6 | sort | uniq -c | sort -rn | head`
    MOST_SENT_IP=`cat $LOGFILE | grep '<=' | egrep -v "$LOCAL_DOMAINS" | grep -o 'H=.*\ \[[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\]' | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sort | uniq -c | sort -rn | head`
    MOST_RCPTS=`cat $LOGFILE | grep '<=' | grep -v mailnull | egrep -v "$LOCAL_DOMAINS" | awk -v NUM_RCPTS="$NUM_RCPTS" ' 

        function shift_list(x)
        {
            y=x
            x++
            while (x <= NUM_RCPTS)
            {
                TOP_RCPTS[x] = TOP_RCPTS[y]
                MAIL_ID[x] = MAIL_ID[y]
                SENDER_ID[x] = SENDER_ID[y]
                x++
                y++
            }
        }

        function save_current()
        {
            SENDER_ID[CUR_NUM]=$6
            MAIL_ID[CUR_NUM]=$4
            TOP_RCPTS[CUR_NUM]=NUM_ADDRESSES
        }

        function display_results()
        {
            CUR_NUM=1
            while (CUR_NUM <= NUM_RCPTS) {
                print MAIL_ID[CUR_NUM], "with", TOP_RCPTS[CUR_NUM], "recipients was sent by", SENDER_ID[CUR_NUM]
                CUR_NUM++
            }
        }

        function duplicate_check()
        {
            x=NUM_RCPTS
            y=x-1
            while (x > 0)
            {
                if (MAIL_ID[x] == MAIL_ID[y])
                {
                    MAIL_ID[x]=0
                    TOP_RCPTS[x]=0
                    SENDER_ID[x]=0
                }
                x--
                y--
             }
        }

        BEGIN {
            CUR_NUM=NUM_RCPTS
            while (CUR_NUM > 0){
                MAIL_ID[CUR_NUM] = 0
                TOP_RCPTS[CUR_NUM] = 0
                SENDER_ID[CUR_NUM] = 0
                CUR_NUM--
          }
        }

        {
            split($0,RCPTS_TMP,"from.*for ")
            split(RCPTS_TMP[2],RCPTS," ")

            NUM_ADDRESSES=0
            for (ADDRESSES in RCPTS)
                 ++NUM_ADDRESSES
            CUR_NUM=1
            for (EACH in TOP_RCPTS)
            {
                if (NUM_ADDRESSES > TOP_RCPTS[CUR_NUM])
                {
                    shift_list(CUR_NUM)
                    save_current()
                    duplicate_check()
                    break
                }
                CUR_NUM++
            }
        }
        END {
            display_results()
        }
    '`
}



display_results()
{
    echo  "Emails sent from scripts:"
    echo  "$SCRIPTED_EMAILS"
    echo 
    echo  "Most frequent senders by email address:"
    echo  "$MOST_SENT_DOMAIN"
    echo
    echo  "Most frequent senders by IP address:"
    echo  "$MOST_SENT_IP"
    echo
    echo  "Most recipients by Mail and Sender ID's:"
    echo  "$MOST_RCPTS"
}

check_for_scripts
check_for_auth
check_most_sent

display_results


