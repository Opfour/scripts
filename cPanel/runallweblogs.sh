#! /bin/sh
# Built by Jared Hewitt
# Concept by Mike Neir
#
# A quick sloppy script to get all accounts weblogs
# updated. Usefull for those dedicated servers where
# they measure success by number of hits.

ROOT_UID=0     # Only users with $UID 0 have root privileges.
E_NOTROOT=67   # Non-root exit error.
E_XCD=66       # Can't change directory.

# First determine if we are root, and if we should even be
# running this script.
if [ "$UID" -ne "$ROOT_UID" ]
then
  echo "Must be root to run this script."
  exit $E_NOTROOT
fi

# Determine your current working directory, so we can
# return to it.
RETURN=$PWD

# Enter the cpanel user directory so we have a working
# list of all active accounts.
cd /var/cpanel/users 2> /dev/null

# Check to see if we actually made it into the cpanel
# users directory.

if [ "$PWD" != "/var/cpanel/users" ]
then
  echo "Couldn't enter the cpanel users directory."
  exit $E_XCD
fi

# Some colorful text.  
echo "Running weblogs for all users..."

# Now we can run the weblogs.
for user in *; do /scripts/runweblogs $user; done

# More colorful text.
echo "Running weblogs completed."

# Return to the former working directory so there's 
# no confusion.
cd $RETURN

exit 0

