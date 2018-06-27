#alias SSH='/usr/bin/ssh' 
#This goes at the top of .bashrc
#normal bashrc stuff here then the ssh function at the bottom
#!/bin/bash

function ssh
{
        OLD_PROMPTCOMMAND=$PROMPT_COMMAND

        DEST=`echo $1 | cut -d @ -f 2`

        if [[ "$DEST" =~ "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" ]];
        then
                FINALDEST=`host $DEST | cut -d " " -f 5`

                if [ "$FINALDEST" == "3(NXDOMAIN)" ] ;
                then
                        FINALDEST=$DEST;
                fi
        else
                FINALDEST=$DEST
        fi


        DETACHED=`screen -list | grep Detach | awk '{print $1}' | \
           egrep $FINALDEST$| head -n 1`

        #echo "DETACHED=$DETACHED";     

        if [[ "$DETACHED" =~ "^[0-9]{1,5}\.$FINALDEST$" ]];
        then
                #echo "we already have a terminal open! connect!"
                /usr/bin/screen -r $DETACHED
        else
                #echo "nothing open, new connection"
                /usr/bin/screen -S "$FINALDEST" -t "$FINALDEST" /usr/bin/ssh $*
        fi


}

function lsscr
{
        OLDIFS=$IFS
        
        IFS=$'\n'
        OUTPUT=`
        for line in \`screen -list\`; do 
        if [[ "$line" =~ "([0-9]{1,5})\.(\S+)\s+\((\S+)\)" ]]; 
        then
                echo "${BASH_REMATCH[2]} ${BASH_REMATCH[1]} ${BASH_REMATCH[3]}";
        fi

        done;
        `


        AOUTPUT=`echo "$OUTPUT" | grep Attached | sort`
        DOUTPUT=`echo "$OUTPUT" | grep Detached | sort`
        
        if [ "$#" != "0" ];
        then 
                AOUTPUT=`echo "$OUTPUT" | grep Attached | sort | grep $1`
                DOUTPUT=`echo "$OUTPUT" | grep Detached | sort | grep $1`
        else    
                AOUTPUT=`echo "$OUTPUT" | grep Attached | sort`
                DOUTPUT=`echo "$OUTPUT" | grep Detached | sort`
        fi      
        
        if [ "$DOUTPUT" != "" ];
        then 
                echo "Detached Screens:"
                echo "$DOUTPUT" | awk '{printf "%7s.%s\n", $2, $1}'
        fi      
        

        if [ "$AOUTPUT" != "" ];
        then 
                echo "Attached Screens:"
                echo "$AOUTPUT" | awk '{printf "%7s.%s\n", $2, $1}'
        fi      
        
        IFS=$OLDIFS
        unset OLDIFS
        unset OUTPUT
        unset AOUTPUT
        unset DOUTPUT
}


