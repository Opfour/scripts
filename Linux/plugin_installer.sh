#By Mark Benedict
# 09/29/2012
#Version 1.0
clear
echo "What WHM Plugin would you like to install?"
echo ""
PS3='Please enter your choice: '
echo ""
options=("Server Wide" "Apache" "MySQL" "Mail Queues" "Mail Manage" "Clean Backups" "Domain Statistics" "Watch MySQL" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Server Wide")
STUFF
            break
            ;;
        "Apache")
STUFF
            break
            ;;
        "MySQL")
STUFF
            break
            ;;
        "EMail")
#Check auth deamons and if alot are being used.
            break
            ;;
        "Mail Manage")
STUFF
            break
            ;;
        "Clean Backups")
STUFF
            break
            ;;
        "Domain Statistics")
STUFF
            break
            ;;
        "Watch MySQL")
STUFF
            break
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
