#! /bin/bash

# characters allowed in our passwords
charspool=('a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j' 'k' 'l' 'm' 'n' 'o' 'p'
'q' 'r' 's' 't' 'u' 'v' 'w' 'x' 'y' 'z' '0' '1' '2' '3' '4' '5' '6' '7'
'8' '9' '0' 'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N' 'O'
'P' 'Q' 'R' 'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z');

len=$

if [ $# -lt 1 ]; then
        num=6;
else
       num=;
fi

while read line

do
for c in $(seq $num); do
        pass="$pass$"
done

# output the to the csv file
# modify path to YOUR home directory
echo -e "$line,$pass" >> /home/username/passwords.csv

# email subject
SUBJECT="Your Login Details"
# Email To ?
EMAIL=$line
# Email text/message
EMAILMESSAGE="/tmp/emailmessage.txt"

echo "You can login to whatever using the following details:">>$EMAILMESSAGE
echo "">>$EMAILMESSAGE
echo "Email Address = $line">>$EMAILMESSAGE
echo "Password = $pass">>$EMAILMESSAGE
echo "">>$EMAILMESSAGE
echo "">>$EMAILMESSAGE
echo "">>$EMAILMESSAGE
echo "Signature or URL or whatever">>$EMAILMESSAGE

# send email using /bin/mail
#change sending email address to your own!
/usr/bin/mail -s "$SUBJECT" "$EMAIL" -- -f username@domain.com< $EMAILMESSAGE

# reset password to go again
pass=""

# input file - modify path to YOUR home directory
done </home/username/emails.txt
