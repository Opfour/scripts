#By Mark Benedict
# 09/29/2012
#Version 1.0
clear
echo "What WHM Plugin would you like to install?"
echo ""
PS3='Please enter your choice: '
echo ""
options=("Security Firewall" "ModSecurity Control" "Explorer" "Mail Queues" "Mail Manage" "Clean Backups" "Domain Statistics" "Watch MySQL" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Security Firewall")
            echo "This will not uninstall APF"
            sleep 4
            echo ""
            echo ""
            echo "Installing."
            cd /home/temp/
            wget http://www.configserver.com/free/csf.tgz
            tar zxvf csf.tgz
            cd csf
            ./install.cpanel.sh
            /etc/init.d/csf restart
            echo "Done"
            echo "Cleaning Temp Folders"
            rm -Rfv csf/ csf.tgz
            clear
            break
            ;;
        "ModSecurity Control")
            echo "Installing"
            cd /home/temp/
            wget http://www.configserver.com/free/cmc.tgz
            tar -xzf cmc.tgz
            cd cmc/
            sh install.sh
            echo "Cleaning Temp Folders"
            rm -Rfv cmc/ cmc.tgz
            echo "Done"
            clear
            break
            ;;
        "Explorer")
            echo "Installing"
            cd /home/temp/
            wget http://www.configserver.com/free/cse.tgz
            tar -xzf cse.tgz
            cd cse
            sh install.sh
            echo "Cleaning Temp Folders"
            rm -Rfv cse/ cse.tgz
            echo "Done"
            clear
            break
            ;;
        "Mail Queues")
            echo "Installing"
            cd /home/temp/
            wget http://www.configserver.com/free/cmq.tgz
            tar -xzf cmq.tgz
            cd cmq/
            sh install.sh
            echo "Cleaning Temp Folders"
            rm -Rfv cmq/ cmq.tgz
            echo "Done"
            clear
            break
            ;;
        "Mail Manage")
            echo "Installing"
            cd /home/temp/
            wget http://www.configserver.com/free/cmm.tgz
            tar -xzf cmm.tgz
            cd cmm/
            sh install.sh
            echo "Cleaning Temp Folders"
            rm -Rfv cmm/ cmm.tgz
            echo "Done"
            clear
            break
            ;;
        "Clean Backups")
            echo "Installing"
            cd /home/temp/
            wget http://www.ndchost.com/cpanel-whm/plugins/cleanbackups/download.php
            sh latest-cleanbackups
            echo "Done"
            clear
            break
            ;;
        "Domain Statistics")
            echo "Installing"
            cd /home/temp/
            wget -O ds-v3.0.tar http://domainsstatistics.gk-root.com/downloads/download.php
            tar -xf ds-v3.0.tar
            cd ds-latest
            sh install.sh
            echo "Cleaning Temp Folders"
            cd /home/temp/
            rm -Rfv ds-latest/ ds-v3.0.tar
            echo "Done"
            clear
            break
            ;;
        "Watch MySQL")
            echo "Installing"
            cd /home/temp/
            wget http://www.ndchost.com/cpanel-whm/plugins/watchmysql/download.php
            sh latest-watchmysql
            echo "Done"
            clear
            break
            ;;
        "Quit")
            clear
            break
            ;;
        *) echo invalid option;;
    esac
done
