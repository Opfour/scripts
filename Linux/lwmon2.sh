=Purpose=

lwmon.sh is a monitoring tool. It's designed to help automate the process of monitoring websites or load on a remote server with minimal effort. It outputs color-coded data for multiple monitoring jobs to a single terminal window, allowing the user to be constantly aware of the status of each monitoring job without having to put forth specific effort.

=Installation=

Run the following on your workstation or VPS:

Script location: http://g33kinfo.com/scripts/lwmon.sh 

<source lang='bash'>
wget -O ./lwmon.sh http://g33kinfo.com/scripts/lwmon.sh
chmod +x ./lwmon.sh
</source>

=Troubleshooting=
or How do I make this huge ass script work?

=="mail needs to be installed"==

The ability to send email alerts regarding changes in monitoring status is a key feature of lwmon.sh. If you don't have the "mail" binary installed, you will get this message when trying to run the script:

 mail needs to be installed for lwmon to perform some of its functions. Exiting.

or

 The "mail" binary needs to be installed for lwmon to perform some of its functions. Exiting.

This is fairly easy to resolve:

* http://tecadmin.net/bash-mail-command-not-found/#

As of version 2.3.1, this no longer prevents the script from running entirely, and instead just warns the user and prevents the script from attempting to send mail.

=How To Make It Do The Things=

lwmon.sh has a number of command line options to start monitoring jobs, as well as a system of menus to modify and view data related to existing jobs. You can read more about them by running either (or both!) of the following:

<source lang='bash'>
./lwmon.sh --help
</source>
<source lang='bash'>
./lwmon.sh --help-flags
</source>

The first monitoring job created with lwmon.sh will output text in the terminal session in which it is opened. Additional jobs opened from the command line in other terminal windows will output to the session of the original job as well - thus only one visible terminal session is necessary to monitor multiple things.

==Monitor A URL==
To monitor a URL, lwmon.sh will repeatedly curl the URL in question and then check the result for a specific string of text. If the string of text is present in the result, it will count as a success, otherwise it will count as a failure. The best way to find an appropriate string of text is to run "curl -L" against whatever URL you're monitoring, and select something from what's present - preferably select a portion of the site that isn't likely to disappear if the customer makes an update to their content (For example - text from headers and footers on a wordpress site are good things to choose from, whereas text from within an article on the front page might disappear or change before too long)

===Examples===

<source lang='bash'>
./lwmon.sh --url sporks5000.com --string "Other Side of the Moon"
</source>

The above will repeatedly (the default is every 10 seconds, but you can change this) curl the URL sporks5000.com, and return successful if the string "Other Side of the Moon" is present.

<source lang='bash'>
./lwmon.sh --url domain.com --string "taco time ALL the time" --ip-address 72.51.28.74 --seconds 30 --check-timeout 15 --user-agent
</source>

The above will curl for domain.com specifically at IP address 72.51.28.74 (regardless where DNS or hosts files might be pointing) every 30 seconds. If the curl command doesn't get a response after 15 seconds, it will fail automatically (the default is 10 seconds), and it will pretend to use the google chrome user agent rather than the default lwmon.sh user agent.

==Monitor Ping==

Using lwmon.sh to monitor the ping of a server is beneficial over just using the "ping" command, because 1) it produces output indicating whether the ping is a success or failure (rather than just for successes), and 2) it provides timestamps. With this, for example, you can tell a customer exactly when their server stopped pinging and then started pinging again for a reboot during a server resize.

===Examples===

<source lang='bash'>
./lwmon.sh --ping 72.51.28.74 --seconds 2
</source>

The above will ping IP 72.51.28.74 every two seconds, and report whether the ping succeeds or fails.

<source lang='bash'>
./lwmon.sh --ping domain.com --seconds 2 --outfile /var/log/lwmon.output.log --mail user@domain.com --mail-delay 3 --nsr 15 --nsns 4
</source>

The above will resolve the domain "domain.com" to an IP and then ping that IP every two seconds. Rather than outputting to the window where the master lwmon.sh process is running, the monitoring job will output the results of each check to the file "/var/log/lwmon.output.log". If at any point in time, three pings in a row fail, an email will be sent to user@domain.com with information about the status of the job (similarly, if three pings in a row succeed after having failed for a while, an email will be sent). In addition to this, if out of any 15 consecutive pings, four of them are failures (but never three in a row, the number specified to trigger an e-mail otherwise), an e-mail will be sent indicating that this is the case.

==Monitor Load==
lwmon.sh can be used to monitor load on a remote server (or locally). Instead of outputting whether a check passed or failed, the script will output the load. The user can use the "--load-ps" and "--load-fail" flags to cause color changes to the text that's being output in order to better grab their attention if the load goes higher than they would like.

Monitoring load requires the presence of an ssh control socket in order to access the remote machine. Don't worry, the script will tell you how to set this up, as shown below:

 [~]# ./lwmon.sh --ssh-load remote.domain.com --user root --port 255 --load-ps 0.10 --load-fail 0.20
 
 There doesn't appear to be an SSH control socket open for this server. Use the following command to SSH into this server (you'll probably want to do this in another window, or a screen), and then try starting the job again:
 
 ssh -o ControlMaster=auto -o ControlPath="~/.ssh/control:%h:%p:%r" -p 255 root@remote.domain.com
 
 Be sure to exit out of the master ssh process when you're done monitoring the remote server.

===Examples===

<source lang='bash'>
./lwmon.sh --ssh-load localhost --load-ps 1.25 --load-fail 2.45
</source>

The above will output the load locally, reporting as a partial success at 1.25 or above, and a failure if the load is 2.45 or above.

<source lang='bash'>
./lwmon.sh --ssh-load domain.com --user root --port 22 --load-ps 4 --load-fail 8 --seconds 5 --ctps 6
</source>

The above will connect to domain.com on port 22 and output the load on that server every five seconds. If the load is 4 or higher, the output colors will indicate that the check was a partial success; if the load is 8 or higher, the output colors will indicate that the check is a failure. If for some reason the check takes six seconds or more to complete but otherwise would be counted as a success, the color of the output will only indicate a partial success, thus alerting the user that there might be something amiss.

==Monitoring DNS Services==
lwmon.sh can be used to monitor DNS services on a server. This was very useful back in 2013 when DNS was one of the first things that would routinely go down on an overloaded cPanel server. It's not as useful now, but the functionality is still present. lwmon.sh will make a dns query to the remote server for a domain known to be on the server. If a result is returned, the check is considered a success.

===Examples===

<source lang='bash'>
./lwmon.sh --dns host.domain.com --domain domain.com --seconds 30
</source>

The above will run a dig at host.domain.com for the domain "domain.com" every thirty seconds. So long as it gets a result, the check will be considered successful.

<source lang='bash'>
./lwmon.sh --dns host.domain.com --domain domain.com --record-type txt --check-result "v=spf1 +a +mx" --job-name "domain.com - ticket ref#1234567"
</source>

The above will run a dig at host.sporks5000.com for "txt" records for the domain "domain.com". Only if the results contain the string "v=spf1 +a +mx" will the check be considered successful. The job name that's reported in the lwmon.sh output will be "domain.com - ticket ref#1234567" assuming you are using some kind of ticketing system to keep track of your server issues.

=Modifying Existing Jobs=

When the user runs "./lwmon.sh --modify", they are given a numbered list of currently running jobs. When they select a number from the list, they are given options for how to move forward with the job in question. An example:

 [root@remote ~]# ./lwmon.sh --url domain.com --string "Other Side of the Moon" --seconds 30
 [root@remote ~]# ./lwmon.sh --modify
 List of currently running lwmon processes:
 
   1) [30872] - Master Process (and lwmon in general)
   2) [10554] - url domain.com
 
 Which process do you want to modify? 2
 domain.com:
 
   1) Kill this process.
   2) Output the command to go to the working directory for this process.
   3) Directly edit the parameters file (with your EDITOR - "vim").
   4) View the log file associated with this process.
   5) Output the commands to reproduce this job.
   6) Change the title of the job as it's reported by the child process. (Currently "sporks5000.com").
   7) Output the "more verbose" output once, then return to current verbosity.
   8) View associated html files (if any).
   9) Exit out of this menu.
 
 Choose an option from the above list:

The menu options are all fairly self explanatory, however option #3 specifically is the one you want to use in order to make modifications to an existing job. This option allows you to edit the parameters that were specified by the command line flags when the job was created. An example:

 JOB_TYPE = url
 CURL_URL = domain.com
 CURL_STRING = Other Side of the Moon
 USER_AGENT = false
 IP_ADDRESS = false
 USE_WGET = false
 JOB_NAME = domain.com
 ORIG_JOB_NAME = domain.com
 #CHECK_TIME_PARTIAL_SUCCESS =
 #CHECK_TIMEOUT =
 WAIT_SECONDS = 30
 #EMAIL_ADDRESS =
 #MAIL_DELAY =
 #VERBOSITY =
 #OUTPUT_FILE =
 #CUSTOM_MESSAGE =
 #LOG_DURATION_DATA =
 #NUM_DURATIONS_RECENT =
 #NUM_STATUSES_RECENT =
 #NUM_STATUSES_NOT_SUCCESS =

For more information about what the different directives in this file do, you can run the following:

<source lang='bash'>
./lwmon.sh --help-params-file
</source>

=Limitations=

This script has been tested on Debian, Mint, and CentOS 5, and 6 without issues. I can make no guarantees for other OS's.


