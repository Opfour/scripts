#Summary: Corrects common issues that are often encountered when switching to CGI/FCGI/suPHP (with suexec enabled). Also has ability to backup changes for later restores.
#Name: suPHPfix
#Version: 3.0.0
#Release: 2
#Group:          Applications/System
#Source: http://layer3.liquidweb.com/scripts/suphpfix-%{version}.tar.gz
#URL: http://www.liquidweb.com
#License: Proprietary
#Prefix: %{_prefix}
#BuildRoot: %{_tmppath}/%{name}-%{version}-root
#BuildArch:  noarch
#AutoReqProv: no
#AutoReq: 0
#AutoProv: 0

#%description
#suPHPfix (cPanel only) corrects common permission/ownership issues (as well as some PHP setting issues) that are commonly encountered when switching to CGI/FCGI/suPHP (with suexec enabled). suPHPfix also has the ability to restore cPanel accounts to the state they were in before it made any changes. This is useful when customers decide CGI/FCGI/suPHP (with suexec enabled) is not for them and you wish to undo/revert all changes made by suPHPfix.

%prep
%setup -q

%install
rm -fr ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}/usr/local/lp/share/suPHPfix
mkdir -p ${RPM_BUILD_ROOT}/usr/local/lp/logs
mkdir -p ${RPM_BUILD_ROOT}/usr/local/lp/var/suphpfix
mkdir -p ${RPM_BUILD_ROOT}/usr/local/lp/apps

install -m700 suphpfix ${RPM_BUILD_ROOT}/usr/local/lp/apps/suphpfix
install -m644 share/suPHPfix/API.pm ${RPM_BUILD_ROOT}/usr/local/lp/share/suPHPfix/API.pm
install -m644 share/suPHPfix/Prep.pm ${RPM_BUILD_ROOT}/usr/local/lp/share/suPHPfix/Prep.pm
install -m644 share/suPHPfix/Save.pm ${RPM_BUILD_ROOT}/usr/local/lp/share/suPHPfix/Save.pm
install -m644 share/suPHPfix/Restore.pm ${RPM_BUILD_ROOT}/usr/local/lp/share/suPHPfix/Restore.pm
install -m644 share/suPHPfix/Base.pm ${RPM_BUILD_ROOT}/usr/local/lp/share/suPHPfix/Base.pm

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/usr/local/lp/apps/suphpfix
/usr/local/lp/share/suPHPfix/API.pm
/usr/local/lp/share/suPHPfix/Prep.pm
/usr/local/lp/share/suPHPfix/Save.pm
/usr/local/lp/share/suPHPfix/Restore.pm
/usr/local/lp/share/suPHPfix/Base.pm

%post
if [ -f /scripts/perlinstaller ]; then
        /scripts/perlinstaller JSON
else
  echo "WARNING: '/scripts/perlinstaller' doesn't exist, is this even a cPanel machine?"
fi
if [ ! -h /usr/bin/suphpfix ]; then
        ln -s /usr/local/lp/apps/suphpfix /usr/bin/suphpfix
fi
if [ ! -h /usr/local/cpanel/scripts/suphpfix ]; then
	ln -s /usr/local/lp/apps/suphpfix /usr/local/cpanel/scripts/suphpfix
fi

%changelog
* Mon Jan 30 2012 Scott Sullivan <ssullivan@liquidweb.com> 3.0.0-2
- Don't check size of logs if they do not exist.
* Tue Jan 24 2012 Scott Sullivan <ssullivan@liquidweb.com> 3.0.0-1
- Two dumb bug fixes. Can't create the lock file if the lock file dir doesn't exist yet. 
- Fixed typo in file check for null.
* Tue Jan 24 2012 Scott Sullivan <ssullivan@liquidweb.com> 3.0.0-0
- Complete rewrite, using OO standard practices. Various performance gains as well.
* Tue Dec 27 2011 Scott Sullivan <ssullivan@liquidweb.com> 2.2.4
- Updated SPEC file so it doesn't automatically add perl module deps as it sees fit.
* Mon Dec 20 2010 Scott Sullivan <ssullivan@liquidweb.com> 2.0
- Initial RPM offering.
