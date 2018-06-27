#!/bin/bash -o compat31

###Variables
#Version check
OSVER=`cat /etc/redhat-release`
#Only shows major version number of OS
OSFAMILY=`cat /etc/redhat-release | awk '{print $3}' | awk -F. '{print $1}'`
#Creates variable for hostname
HOST=`hostname`
#Creates variable for BASH version
BASHVER=`rpm -qid bash | grep Version | awk '{print $3}'`
#Sets old yum path
LPYUM=`yum -c /usr/local/lp/configs/yum/yum.conf 2> /dev/null`

#Displays above varibles
echo -e "\e[4mHostname\e[24m:"
echo -e $HOST"\n"
echo -e "\e[4mServer OS\e[24m:"
echo -e $OSVER"\n"
echo -e "\e[4mBASH Version\e[24m:"
echo -e $BASHVER"\n"

#Checks if yum can find itself
echo -e "\e[4mChecks if yum can find itself\e[24m:"
if [[ "4" = `echo $OSFAMILY` ]]
   #Since CentOS 4 uses a special yum -c path this accounts of it. (still needs to be adjusted)
   then yum -c /usr/local/lp/configs/yum/yum.conf list yum
   else yum list yum
fi
echo -e "\n"

#Runs test for ShellShock
echo -e "\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock 
echo -e "\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#Main Menu
function start_screen
{
    #Shows Main Menu
    echo " Choose BASH version to upgrade"
    echo " (1) 2.05b"
    echo " (2) 3.0"
    echo " (3) 3.1"
    echo " (4) 3.2"
    echo " (5) 4.1"
    echo " (6) Exit"
    echo -n "Select Option: "
    read main_menu_options

#Options from Main Menu
case $main_menu_options in
	1)
		bash_2_05b_yum
		;;
        2)
                bash_3_0_yum
                ;;
        3)
                bash_3_1_yum
                ;;
        4)
                bash_3_2_yum
                ;;
	5)
		bash_4_1_yum
		;;
	6)
		echo "Goodbye"
		exit
		;;
	*)
		echo -e "Not an option, try again."
		start_screen
		;;
esac

}

#Attempts to install BASH via yum
bash_2_05b_yum()
{

#Checks if server is running CentOS 1
if [[ "1" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 2
if [[ "2" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 3
if [[ "3" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 4
if [[ "4" = `echo $OSFAMILY` ]]
   #Since CentOS 4 uses a special yum -c path this accounts of it.
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum -c /usr/local/lp/configs/yum/yum.conf clean all; yum -c /usr/local/lp/configs/yum/yum.conf update bash
fi
#Checks if server is running CentOS 5
if [[ "5" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 6
if [[ "6" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 7
if [[ "7" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi

#Runs test for ShellShock
echo -e "\n\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#If yum install fails gives option to install from source
read -r -p "Install from source? [y/N] " response
case $response in
    [yY][eE][sS]|[yY]) 
        bash_2_05b_source
        ;;
    *)
        exit
        ;;
esac
}

#Installs BASH 2.05b from pre-patched source
bash_2_05b_source()
{
#Makes backup of BASH binary
cp -a /bin/bash{,.`date +%F.%H.%M`}
#Creates directory for BASH update
mkdir /usr/local/src/bashfix
#Goes to newly created directory
cd /usr/local/src/bashfix
#Downloads new BASH binary
wget https://ftp.gnu.org/pub/gnu/bash/bash-2.05b.tar.gz
#Uncompresses tarball
tar xzf bash-2.05b.tar.gz
#Goes to new directory
cd bash-2.05b
#Applies patches
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-001 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-002 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-003 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-004 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-005 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-006 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-007 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-008 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-009 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-010 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-011 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-012 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-2.05b-patches/bash205b-013 | patch -p0
#Configures and makes new BASH binary
./configure && make && make test
#Copies new binary to /bin
cp -f ./bash /bin/bash

#Runs test for ShellShock
echo -e "\n"
echo -e "\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#Reminder to add sticky to Billing about compiling from source
echo -e "\e[0;31mAdd sticky to $HOST's Billing:\nBASH was updated manually and will not verify correctly if 'rpmverify' is run.\e[0m\n"

}

#Attempts to install BASH via yum
bash_3_0_yum()
{

#Checks if server is running CentOS 1
if [[ "1" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 2
if [[ "2" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 3
if [[ "3" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 4
if [[ "4" = `echo $OSFAMILY` ]]
   #Since CentOS 4 uses a special yum -c path this accounts of it.
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum -c /usr/local/lp/configs/yum/yum.conf clean all; yum -c /usr/local/lp/configs/yum/yum.conf update bash
fi
#Checks if server is running CentOS 5
if [[ "5" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 6
if [[ "6" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 7
if [[ "7" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi

#Runs test for ShellShock
echo -e "\n\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\n\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#If yum install fails gives option to install from source
read -r -p "Install from source? [y/N] " response
case $response in
    [yY][eE][sS]|[yY])
        bash_3_0_source
        ;;
    *)
        exit
        ;;
esac
}

bash_3_0_source()
{
#Makes backup of BASH binary
cp -a /bin/bash{,.`date +%F.%H.%M`}
#Creates directory for BASH update
mkdir /usr/local/src/bashfix
#Goes to newly created directory
cd /usr/local/src/bashfix
#Downloads new BASH binary
wget https://ftp.gnu.org/pub/gnu/bash/bash-3.0.tar.gz
#Uncompresses tarball
tar xzf bash-3.0.tar.gz
#Goes to new directory
cd bash-3.0
#Applies patches
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-001 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-002 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-003 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-004 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-005 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-006 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-007 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-008 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-009 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-010 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-011 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-012 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-013 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-014 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-015 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-016 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-017 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-018 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-019 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-020 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-021 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.0-patches/bash30-022 | patch -p0
#Configures and makes new BASH binary
./configure && make && make test
#Copies new binary to /bin
cp -f ./bash /bin/bash

#Runs test for ShellShock
echo -e "\n"
echo -e "\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#Reminder to add sticky to Billing about compiling from source
echo -e "\e[0;31mAdd sticky to $HOST's Billing:\nBASH was updated manually and will not verify correctly if 'rpmverify' is run.\e[0m\n"

}

#Attempts to install BASH via yum
bash_3_1_yum()
{

#Checks if server is running CentOS 1
if [[ "1" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 2
if [[ "2" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 3
if [[ "3" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 4
if [[ "4" = `echo $OSFAMILY` ]]
   #Since CentOS 4 uses a special yum -c path this accounts of it.
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum -c /usr/local/lp/configs/yum/yum.conf clean all; yum -c /usr/local/lp/configs/yum/yum.conf update bash
fi
#Checks if server is running CentOS 5
if [[ "5" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 6
if [[ "6" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 7
if [[ "7" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi

#Runs test for ShellShock
echo -e "\n\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\n\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#If yum install fails gives option to install from source
read -r -p "Install from source? [y/N] " response
case $response in
    [yY][eE][sS]|[yY])
        bash_3_1_source
        ;;
    *)
        exit
        ;;
esac
}

bash_3_1_source()
{
#Makes backup of BASH binary
cp -a /bin/bash{,.`date +%F.%H.%M`}
#Creates directory for BASH update
mkdir /usr/local/src/bashfix
#Goes to newly created directory
cd /usr/local/src/bashfix
#Downloads new BASH binary
wget https://ftp.gnu.org/pub/gnu/bash/bash-3.1.tar.gz
#Uncompresses tarball
tar xzf bash-3.1.tar.gz
#Goes to new directory
cd bash-3.1
#Applies patches
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-001 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-002 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-003 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-004 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-005 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-006 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-007 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-008 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-009 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-010 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-011 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-012 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-013 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-014 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-015 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-016 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-017 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-018 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-019 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-020 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-021 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-022 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.1-patches/bash31-023 | patch -p0
#Configures and makes new BASH binary
./configure && make && make test
#Copies new binary to /bin
cp -f ./bash /bin/bash

#Runs test for ShellShock
echo -e "\n"
echo -e "\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#Reminder to add sticky to Billing about compiling from source
echo -e "\e[0;31mAdd sticky to $HOST's Billing:\nBASH was updated manually and will not verify correctly if 'rpmverify' is run.\e[0m\n"

}

#Attempts to install BASH via yum
bash_3_2_yum()
{

#Checks if server is running CentOS 1
if [[ "1" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 2
if [[ "2" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 3
if [[ "3" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 4
if [[ "4" = `echo $OSFAMILY` ]]
   #Since CentOS 4 uses a special yum -c path this accounts of it.
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum -c /usr/local/lp/configs/yum/yum.conf clean all; yum -c /usr/local/lp/configs/yum/yum.conf update bash
fi
#Checks if server is running CentOS 5
if [[ "5" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 6
if [[ "6" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 7
if [[ "7" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi

#Runs test for ShellShock
echo -e "\n\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\n\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#If yum install fails gives option to install from source
read -r -p "Install from source? [y/N] " response
case $response in
    [yY][eE][sS]|[yY])
        bash_3_2_source
        ;;
    *)
        exit
        ;;
esac
}

bash_3_2_source()
{
#Makes backup of BASH binary
cp -a /bin/bash{,.`date +%F.%H.%M`}
#Creates directory for BASH update
mkdir /usr/local/src/bashfix
#Goes to newly created directory
cd /usr/local/src/bashfix
#Downloads new BASH binary
wget https://ftp.gnu.org/pub/gnu/bash/bash-3.2.tar.gz
#Uncompresses tarball
tar xzf bash-3.2.tar.gz
#Goes to new directory
cd bash-3.2
#Applies patches
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-001 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-002 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-003 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-004 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-005 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-006 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-007 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-008 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-009 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-010 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-011 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-012 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-013 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-014 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-015 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-016 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-017 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-018 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-019 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-020 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-021 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-022 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-023 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-024 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-025 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-026 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-027 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-028 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-029 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-030 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-031 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-032 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-033 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-034 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-035 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-036 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-037 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-038 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-039 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-040 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-041 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-042 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-043 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-044 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-045 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-046 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-047 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-048 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-049 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-050 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-051 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-052 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-053 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-054 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-055 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-056 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-057 | patch -p0
#Configures and makes new BASH binary
./configure && make && make test
#Copies new binary to /bin
cp -f ./bash /bin/bash

#Runs test for ShellShock
echo -e "\n"
echo -e "\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#Reminder to add sticky to Billing about compiling from source
echo -e "\e[0;31mAdd sticky to $HOST's Billing:\nBASH was updated manually and will not verify correctly if 'rpmverify' is run.\e[0m\n"

}

#Attempts to install BASH via yum
bash_4_1_yum()
{

#Checks if server is running CentOS 1
if [[ "1" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 2
if [[ "2" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 3
if [[ "3" = `echo $OSFAMILY` ]]
   #Since these versions needs be be updated from source it skips the yum attempt.
   then echo -e "\n\e[0;31mSkipping yum upgrade attempt.  Use source install below.\e[0m\n"
fi
#Checks if server is running CentOS 4
if [[ "4" = `echo $OSFAMILY` ]]
   #Since CentOS 4 uses a special yum -c path this accounts of it.
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum -c /usr/local/lp/configs/yum/yum.conf clean all; yum -c /usr/local/lp/configs/yum/yum.conf update bash
fi
#Checks if server is running CentOS 5
if [[ "5" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 6
if [[ "6" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi
#Checks if server is running CentOS 7
if [[ "7" = `echo $OSFAMILY` ]]
   #Attempts yum update per normal
   then echo -e "\n\e[4mAttempting to upgrade BASH via yum\e[24m:\n"; yum clean all -q; yum update bash
fi

#Runs test for ShellShock
echo -e "\n\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\n\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#If yum install fails gives option to install from source
read -r -p "Install from source? [y/N] " response
case $response in
    [yY][eE][sS]|[yY])
        bash_4_1_source
        ;;
    *)
        exit
        ;;
esac
}

#Installs BASH 4.1 from pre-patched source
bash_4_1_source()
{
#Makes backup of BASH binary
cp -a /bin/bash{,.`date +%F.%H.%M`}
#Creates directory for BASH update
mkdir /usr/local/src/bashfix
#Goes to newly created directory
cd /usr/local/src/bashfix
#Downloads new BASH binary
wget https://ftp.gnu.org/pub/gnu/bash/bash-4.1.tar.gz
#Uncompresses tarball
tar xzf bash-4.1.tar.gz
#Goes to new directory
cd bash-4.1
#Applies patches
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-001 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-002 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-003 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-004 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-005 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-006 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-007 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-008 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-009 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-010 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-011 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-012 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-013 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-014 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-015 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-016 | patch -p0
curl -ks https://ftp.gnu.org/pub/gnu/bash/bash-4.1-patches/bash41-017 | patch -p0
#Configures and makes new BASH binary
./configure && make && make test
#Copies new binary to /bin
cp -f ./bash /bin/bash

#Runs test for ShellShock
echo -e "\n"
echo -e "\e[4mBASH ShellShock Test\e[24m: (Should only say \"test\")"
env 'x=() { :;}; 2> /dev/null echo vulnerable' 'BASH_FUNC_x()=() { :;}; echo vulnerable 2> /dev/null' bash -c "echo test"; echo -e "\n"

#Runs test for secondary test ShellShock
echo -e "\e[4mCVE-2014-7169 Test\e[24m: (Should only show \"date\" and a cat error)"
cd /tmp; rm -f /tmp/echo; env 'x=() { (a)=>\' bash -c "echo date"; cat /tmp/echo
echo -e "\n"

#Reminder to add sticky to Billing about compiling from source
echo -e "\e[0;31mAdd sticky to $HOST's Billing:\nBASH was updated manually and will not verify correctly if 'rpmverify' is run.\e[0m\n"
}

start_screen
