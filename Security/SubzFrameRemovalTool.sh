#!/bin/bash
#written by Steven Sublett
#Best effort script to remove iframe injections

###~~~~~~~~~~~~~~~ Variables
PID=$$


###~~~~~~~~~~~~~~~ Funtions

function START {
	read -p 'Have you made a list of infected files?  ' startanswer
	        if [ -z $startanswer ]; then
	                echo -e "You must type "'\E[1;32m'"yes"`tput sgr0`" or "'\E[1;31m'"no"`tput sgr0`"."
	                START
	        elif [ $startanswer = yes ]; then
	                echo "Proceed."
	        elif [ $startanswer = no ]; then
	                echo "Please make a file with the list of infected files in it and restart the script."
			exit 1
	        else
	                echo -e "Spelling error perhaps? You must type "'\E[1;32m'"yes"`tput sgr0`" or "'\E[1;31m'"no"`tput sgr0`"."
	                START
	        fi
}

function main {
	read -p 'What is your Iframe?  ' answer
	        echo "$answer"
	
	read -p 'What is your file list? (please use full path to file)  ' answer2
	
	echo "We need to remove this line"
	        echo $answer
	
	echo "from these files"
	        for each in `cat $answer2`; do echo $each;done
	
	echo "NEXT show tasks on the list"
	        echo -e "#!/bin/bash\n" > /tmp/$PID.frameremove
	        for each1 in `cat $answer2`;do echo "sed -i -e 's#$answer##g' $each1";
	echo "sed -i -e 's#$answer##g' $each1" >> /tmp/$PID.frameremove ;
	done
	
	echo "NOW do it"
	        /bin/bash /tmp/$PID.frameremove
}

function redo {
	read -p 'Would you like to remove the temp file that this script made? ' answer3
	        if [ -z $answer3 ]; then
	                echo -e "You must type "'\E[1;32m'"yes"`tput sgr0`" or "'\E[1;31m'"no"`tput sgr0`"."
	                redo
	        elif [ $answer3 = yes ]; then
	                echo "Removing /tmp/$PID.frameremove, have a nice day."
			rm -fv /tmp/$PID.frameremove
	        elif [ $answer3 = no ]; then
	                echo "Please remove /tmp/$PID.frameremove, when you are ready to."
	        else
	                echo -e "spelling error perhaps? You must type "'\E[1;32m'"yes"`tput sgr0`" or "'\E[1;31m'"no"`tput sgr0`"."
	                redo
	        fi
}


###~~~~~~~~~~~~~~~ LOGIC
if ! id | grep -q "uid=0(root)" ; then
  echo "ERROR:  You must be root to run this."
  exit 1
fi

echo -e '\E[1;36m'"\n\n\nWELCOME "`tput sgr0`'\E[1;33m'"to "`tput sgr0`'\E[1;34m'"SuBz"`tput sgr0`" "'\E[1;35m'"PlAy"`tput sgr0`" "'\E[1;31m'"PlAcE\n\n\n"`tput sgr0`

	START
	main
	redo

