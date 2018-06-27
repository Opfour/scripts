#Hostbuntu
#Simple Ubuntu Hosting Script
#Created By: Mark Benedict
#Created with Ubuntu Server 12.04 LTS
#!/bin/bash
ver=0.5
clear
echo "-----------------"
echo "Hostbuntu $ver"
echo "By: Mark Benedict"
echo "-----------------"
echo ""
PS3='What would you like to do?: '
echo ""
options=("Create Domain" "Remove Domain" "Add Email"  "Install 3rd Party Software" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Create Domain")
               echo "What domain would you like to create?"
               echo "Only enter domain.tld - example.com - No www."
read domain
verify=$(cat /etc/passwd | grep "/home" |cut -d: -f1|grep $domain)
if [[ -z "$verify" ]]
then
useradd -g www-data -m $domain
mkdir /home/$domain/public_html
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.`date +%Y_%m_%d_%H:%M`.bak
echo "
#BEGIN $domain
<VirtualHost *:80>
DocumentRoot "/home/$domain/public_html"
ServerName $domain
ServerAlias $domain www.$domain 
<Directory "/home/$domain/public_html">
allow from all
Options +Indexes
</Directory>
DirectoryIndex index.php index.html
IndexOptions
</VirtualHost>
#END $domain" >> /etc/apache2/apache2.conf
/etc/init.d/apache2 restart
.
else
echo "It appears that domain already exists."

fi
      ;;
            
        "Remove Domain")
        echo "Please note this will remove all domain files and vhosts entries."
    echo "Enter Domain:" 
    read domain
    userdel -r $domain
    cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.`date +%Y_%m_%d_%H:%M`.bak
    sed -e '/#BEGIN $domain/,/#END $domain/c\#BEGIN $domain\n\n#END $domain' /etc/apache2/apache2.conf
    /etc/init.d/apache2 restart
 
      ;;
      
        "Add Email")
        
STUFF
       
      ;;
      
        "Install 3rd Party Software")
        
        


      ;;      
              
              
              
          
              "Quit")
            clear
            break
            ;;
        *) echo invalid option;;
    esac
done