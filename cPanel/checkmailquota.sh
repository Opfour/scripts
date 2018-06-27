#!/bin/sh

# checkmailquota for cPanel 
# Scot Hacker, shackerREMOVETHIS@birdhouse.org
# v. 1.4, Oct. 1, 2005

# This script sends warning messages to owners of near-quota mailboxes
# and a separate summary message to postmaster or other address.
# Must be run as root, or via root crontab.

#   Limitations:
# - Main account holders cannot have mailbox quotas in cPanel, so this script can't check for them
# - Notifications cannot be sent to parent account holders.
# - If a user has  set their quota to "unlimited," nothing will be reported 

# History:

# 1.4: Only sends warning messages if quota usage is less than 100% (so root doesn't get bounce messages)
# 1.3: Tallies # of mailboxes checked and reports back
# 1.2: Now handles domains with missing quota files
# 1.1 : Summary notice to postmaster now optional; checks whether boxtrapper is installed and skips its dirs.


#   Installation:
# - Rename to checkmailquota and place in root's  path (/root/scripts is good)
# - chmod 744 checkmailquota
# - Edit the four vars below and the message text to taste.
# - Create /etc/cron.d/mailquotacheck with the following two lines (to check 4x daily):

# SHELL=/bin/sh
# 15 */4 * * * root /bin/sh /root/scripts/checkmailquota



# Quota percent threshold (expressed as integer between 1 & 100)
quota=85

# Should script send quota warning mail to users, or just to postmaster?
# Set to 0 to skip sending mail to users 
# 1 is highly recommended, but test with 0 first
enable_user_warnings=1

# Should script send overage summaries to postmaster?
enable_postmaster_notice=1

# Postmaster email
postmaster="postmaster@domain.org"



# Define user alert mail text first, as function to be called later.
function send_user_mail {

user_alert_text="
E-MAIL QUOTA WARNING

Warning: The mailbox for account $thispop@$thisdomain is at $percent%
of its quota threshold. To avoid losing  mail, please take steps
to correct this soon.

In most cases, mailboxes run over quota for one of these reasons:

1) Your mail client has not been configured to remove mail from the
server after downloading, or at regular intervals.

2) You may have been storing a lot of mail permanently on the server,
rather than in your mail client (you may be using webmail or IMAP
exclusively, rather than periodically downloading mail to a desktop
application).

3) You may have recently received a number of large attachments,
which could result in a sudden dramatic increase in disk space
consumed by your mailbox.

To avoid losing mail, please delete some mail from the server to
bring your mailbox back under quota. You can do this by deleting
messages through webmail or via IMAP, or by configuring your POP
mail client to remove messages older than, say, two weeks when
checking mail (recommended technique).

You may also opt to have your mailbox quota size increased. If you
do not have access to cPanel for your domain, please contact the
domain owner.

If your mailbox goes over quota, you will not receive further
notification. At that point, incoming mail for this account will
be held in the queue for five days. Bringing the mailbox back under
quota will cause held mail to be released from the queue and into
your mailbox.

After the grace period expires, incoming mail for this mailbox will
be discarded.

Regards, The Postmaster
"

# Send the message
 
# For test run, uncomment the next line and comment out the following
#echo "$user_alert_text" | /bin/mail -s "Warning: Mailbox nearing quota" $postmaster
echo "$user_alert_text" | /bin/mail -s "Warning: Mailbox nearing quota" $thispop@$thisdomain

echo "Sent warning message to $thispop@$thisdomain"

}




# Do not edit below this line
##############

# Zero out temp file from last script run
echo "" > /tmp/mail_quota

# Initialize mailbox counter
num_boxes=0


# Main account loop 
echo 
echo "Listing POP boxes using more than $quota% of quota."

for account in /home/*; do
	account=$(echo $account | sed s#.*/##)
	

	echo 
	echo 
	echo "============================================="
	echo
	echo "User: $account"
	
	
	for domain in /home/$account/etc/*; do
		# Make sure we only read in directories, not other files
		if [ -d $domain ]; then
			thisdomain=$(echo $domain | sed s#.*/##)
			
			# Skip this entire block if "boxtrapper" directory encountered - not quota-related
			if [ $thisdomain != "boxtrapper" ]; then
				echo ""
				echo "$thisdomain:"
				echo -e "%\tOver\tMailbox"
				echo
				
				
				# Read lines from  this domain's quota file, if  present
				# (User may have manually removed their quota file)
				if [ ! -f /home/$account/etc/$thisdomain/quota ]; then
					echo "This domain has no quota file!"
				else
					exec < /home/$account/etc/$thisdomain/quota
				fi
				

				while read mailbox
				do
					# Re-set $over marker
					over=""
					
					thispop=$(echo $mailbox | sed s#:.*##)
					thisquota=$(echo $mailbox | sed s#^.*:##)
					
					# Get actual usage for this mailbox
					# -b shows bytes rather than k.
					usage=$(/usr/bin/du -b -s /home/$account/mail/$thisdomain/$thispop)
					
					# Output needs to be trimmed
					usage=$(echo $usage | sed s#\ .*##)
					
					# Do the math -- divide usage by quota to get percentage
					percent=$(echo "scale=2; $usage/$thisquota*100" | /usr/bin/bc)
					# Convert floating point to integer
					percent=$(echo $percent | /usr/bin/bc -l | awk -F '.' '{ print $1; exit; }')
					
					# Is this mailbox over quota?
					# Only send warning message if quota usage is under 100%; 
					# otherwise messages are never delivered, and also bounce back to root.
					if [ $percent -gt $quota -a $percent -lt 100 ]; then
						over="X"

						# Send alert mail to user via function above, if enabled
						if [ $enable_user_warnings == "1" ]; then
							send_user_mail $thispop $thisdomain $percent
						fi
					fi
					
					
					# Record overage for postmaster even though we're not alerting user above
					# (Here we don't care if account is at 100%)
					if [ $percent -gt $quota ]; then
						
						# Append this overage record to a text file we'll suck back in later
						# and mail to postmaster.
						echo "$percent% :: $thispop@$thisdomain" >> /tmp/mail_quota
						
					fi
					
					
					# Report to shell
					echo -e "$percent%\t$over\t$thispop@$thisdomain"
					
					
					# Increment counter so we know how many mailboxes were checked
					# Note: Count may not be entirely accurate if user has deleted
					# quota file, or if user is using main account for mail rather 
					# than standard cpanel mailbox.
					let "num_boxes += 1"					
					
				done
			fi
		fi

	done

done


# Report number of boxes checked to the shell
echo 
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$num_boxes mailboxes checked"
echo

# Also append mailbox count to summary to be mailed
echo "
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$num_boxes mailboxes checked
" >> /tmp/mail_quota

# Send summary to postmaster
if [ $enable_postmaster_notice == "1" ]; then
	postmaster_msg=$(/bin/cat /tmp/mail_quota)
	echo "$postmaster_msg" | /bin/mail -s "Customer mailboxes near quota" $postmaster
fi

# Th-th-th-that's all folks!
