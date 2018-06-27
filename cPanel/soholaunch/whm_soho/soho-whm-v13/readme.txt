###############################################################################################
###############################################################################################
###  How to setup Soholaunch auto installer for WHM                                         ###
###############################################################################################
###  Company:    Soholaunch                                                                 ###
###  Author:     Joe Lain                                                                   ###
###  Email:      joe.lain@soholaunch.com                                                    ###
###  Website:    http://info.soholaunch.com                                                 ###
###############################################################################################
###############################################################################################

----------------
Overview:
----------------

This doc will walk you through how to install the Soholaunch website builder auto-installer 
directly into WHM.

----------------
Requirements:
----------------

Root access to cPanel server
Know how to use SSH to upload and extract files on a web server.

----------------
How to install the Soholaunch WHM auto installer for Web Hosts:
----------------

This will add a Soholaunch link to the "Add-ons" section of WHM.

1. Download the soho-whm-inst.tar.gz from http://info.soholaunch.com.
2. Login as root through SSH.
3. Upload soho-whm-inst.tar.gz to the /usr/local/cpanel/whostmgr/docroot/cgi folder. 
   If there is no cgi folder, create one.
4. Extract the tar.gz in the cgi folder.
5. Done!

----------------
Support:
----------------

Any questions / issues with these installers can be emailed to me at joe.lain@soholaunch.com.
If your question requires an answer please expect a fair amount of time for responce as this
installer and docs are widely distributed.