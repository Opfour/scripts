#bin/bash
#created by dhultin to test and remove bad tables
#replace hostname with approriate log file location before you begin.
#also there may be a minor issue with mysql data dir 
#if its not defaulted to /var/lib/mysql/
#check this first. 

#stat the .frm files
for file in `tail -30000 /var/lib/mysql/"$(hostname)".err | grep -a 'Could not find' | awk '{print $14}' | cut -f2 -d\' | sort | uniq | sort`; do stat /var/lib/mysql/$file.frm ; done

#confirm the .ibd files do not exist
for file in `tail -30000 /var/lib/mysql/"$(hostname)".err | grep -a 'Could not find' | awk '{print $14}' | cut -f2 -d\' | sort | uniq | sort`; do stat /var/lib/mysql/$file.ibd ; done

#remove the .frm files to fix cpanel backup issues.
for file in `tail -30000 /var/lib/mysql/"$(hostname)".err | grep -a 'Could not find' | awk '{print $14}' | cut -f2 -d\' | sort | uniq | sort`; do rm -f /var/lib/mysql/$file.frm ; done

#crashed tables 
for table in `tail -20000 /var/lib/mysql/"$(hostname)".err | grep -a 'is marked as crashed' | awk '{print $7}' | uniq | sort | uniq | cut -f2 -d. | cut -f1 -d\' | cut -d'/' -f2,3`; do echo "$table" | tr '/' ' ' |xargs mysqlcheck -r; done;

#check tables that are temp but still exist
for table in `tail -20000 /var/lib/mysql/"$(hostname)".err | grep -a 'is marked as crashed' | awk '{print $7}' | uniq | sort | uniq | cut -f2 -d. | cut -f1 -d\' | cut -d'/' -f2,3`; do echo "$table" | tr '/' ' ' |xargs mysqlcheck -r | grep 'create new tempfile' | awk '{print $7}' | sed "s/'./\/var\/lib\/mysql/g;s/'$//g"; done;

#remove the temp tables and then run the repair again
for table in `tail -20000 /var/lib/mysql/"$(hostname)".err| grep -a 'is marked as crashed' | awk '{print $7}' | uniq | sort | uniq | cut -f2 -d. | cut -f1 -d\' | cut -d'/' -f2,3`; do echo "$table" | tr '/' ' ' |xargs mysqlcheck -r | grep 'create new tempfile' | awk '{print $7}' | sed "s/'./\/var\/lib\/mysql/g;s/'$//g" | xargs rm -f; done;
