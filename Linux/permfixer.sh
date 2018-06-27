#SuPHPPermFixer
#Changes File permissions to 644 and directories to 755 in specified directory
#Created By: Mark Benedict
#!/bin/bash
#03/03/13 Added suphp verification

clear
ver=v1.0
echo "suPHP PermFixer $ver"
echo "Mark Benedict"
echo ""
echo "Please report any issues to mbenedict@liquidweb.com"
echo ""
verify=$(/usr/local/cpanel/bin/rebuild_phpconf --current |grep "PHP5 SAPI:" |awk '{ print $3 }')

if [ $verify == suphp ]
then
echo "Use at your own risk, entering the wrong path can cause serious issues."
echo ""
echo "Please enter the full path to the directory you wish to fix."
echo "*************************************"
echo "Example - /home/example/public_html/ "
echo "*************************************"
echo "Path - "
read path
echo "Fixing directories.....755"
find $path -type d -print0 | xargs -I {} -0 chmod 0755 {}
echo "Fixed"
echo "Fixing files.....644"
find $path -type f -print0 | xargs -I {} -0 chmod 0644 {}
echo "Fixed"
echo "Done"
	.
else

echo "Server not using suphp as handler exiting."
exit
	.
fi