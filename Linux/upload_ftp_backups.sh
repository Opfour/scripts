#!/bin/bash

# This script uploads Cpanel backup files to a remote ftp server
# Edit the settings with the proper account info.

FTP_HOST=1.2.3.4

FTP_USER="user_name"

FTP_PASS="password"

FTP_DIR="~" # Set to ~ to use your home directory

LOCAL_DIR="/backup/cpbackup"

# Command to use
# ncftpput [options] remote-host remote-directory local-files...

echo "Uploading backup files to remote host.  This may take some time."
echo

ncftpput -R -u $FTP_USER -p $FTP_PASS $FTP_HOST $FTP_DIR $LOCAL_DIR
