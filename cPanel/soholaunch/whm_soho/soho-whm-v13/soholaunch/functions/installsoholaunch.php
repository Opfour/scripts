<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<style>
a:link {color: blue; text-decoration:none; border-bottom:0px solid blue;}
a:visited {color: blue; text-decoration:none; border-bottom:0px solid blue;}
a:hover {color: #ffc417; text-decoration:none; border-bottom:0px solid #ffc417;}
a:active {color: blue; text-decoration:none; border-bottom:0px solid blue;}
</style>
</head>
<?

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*
Soholaunch Pro Edition Auto Installer
###############################################################################
## Soholaunch(R) Site Management Tool
## Version 4.8
##
## Author: 			Cameron Allen [cameron.allen@soholaunch.com]
## Homepage:	 	http://www.soholaunch.com
## Bug Reports: 	http://bugz.soholaunch.com
## Release Notes:	sohoadmin/build.dat.php
###############################################################################

##############################################################################
## COPYRIGHT NOTICE
## Copyright 1999-2006 Soholaunch.com, Inc.  All Rights Reserved.
##
## This script may be used and modified in accordance to the license
## agreement attached (license.txt) except where expressly noted within
## commented areas of the code body. This copyright notice and the comments
## comments above and below must remain intact at all times.  By using this
## code you agree to indemnify Soholaunch.com, Inc, its coporate agents
## and affiliates from any liability that might arise from its use.
##
## Selling the code for this program without prior written consent is
## expressly forbidden and in violation of Domestic and International
## copyright laws.
###############################################################################

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
error_reporting(0);
ini_set("max_execution_time", "300000");
ini_set("default_socket_timeout", "555");
ini_set("max_post_size", "100M");
###############
$disabled = strtoupper(ini_get("disable_functions"));
$Gateway = strtoupper(php_sapi_name());
$uri  = rtrim(dirname($_SERVER['PHP_SELF']), '/\\');
$extra = $_SERVER['HTTP_HOST'].$uri;
$thisdomain=eregi_replace("^www\.", "", $extra);
$OS = strtoupper(PHP_OS);
$shellpath = "installsoholaunch.php";
$docroot = str_replace(basename(__FILE__), "", __FILE__);
$docfolder = str_replace($shellpath, '', $_SERVER['SCRIPT_NAME']);
$docfolder = eregi_replace($shellpath, '', $docfolder);
$docfolder = eregi_replace("/", '', $docfolder);
$docfolder = "/".$docfolder;
$installform = "<table align=right><tr><td align=center valign=bottom><font style=\"font-size: 10px; font-family: Times New Roman;\"><span  style=\"color: #000000; text-decoration:blink; border-bottom:1px solid blue;\">(Click to Install)</span></font></em></center></font></td></tr>";
$installform .= "<tr><td align=right valign=bottom><form name=\"SMOKE\" method=\"post\" action=\"installsoholaunch.php\">";
$installform .= "<input type=\"hidden\" name=\"todo\" value=\"getfile\">";
$installform .= "<input name=\"install\" TYPE=\"button\" style=\"background-image:url('http://info.soholaunch.com/images/installer/run_installation.gif'); cursor: pointer; width: 106px; height: 109px; border: 1px solid #ffc417;\" onclick=\"document.getElementById('please_wait').style.display='block';document.getElementById('installer_screen').style.display='none';window.setTimeout('document.SMOKE.submit()', 1000);\">";
$installform .= "</td></tr></table>";

if ( eregi("WIN", $OS) ) {
	$Info = "</em>You are about to Install <strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong> on the domain <font color=#0006ef><strong>".$thisdomain."</strong></font> .  If this is a new installation, create a MYSQL database before installation.<strong><font color=\"#ffc417\">  Pro Edition</font></strong> requires it's own MYSQL database.  Click the Run Installation Button Below to Install <strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong></em>.<br><br>&nbsp;&nbsp;  This Server is Running on <strong><font color=\"BLUE\">Windows</font></strong>. If you experience problems installing with this script, or while using <strong><font color=\"#ffc417\">Pro Edition</font></strong>, try changing PHP's Server API to <strong><font color=\"blue\">ISAPI.</font></strong>  This Server's API is: <strong><font color=\"blue\">".$Gateway."</font></strong>.  You may need to contact your Host to make this change.<br><br>";
} ELSE {
  $Info = "</em>You are about to Install <strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong> on the domain <font color=#0006ef><strong>".$thisdomain."</strong></font> .  If this is a new installation, create a MYSQL database before installation.<strong><font color=\"#ffc417\">  Pro Edition</font></strong> requires it's own MYSQL database.  Click the Run Installation Button Below to Install <strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong></em>.<br><br>";
}

$testfile = $docroot."test.txt";
$file = fopen($testfile, "w");
	if ( !fwrite($file, "test") ) { 
		if ( eregi("WIN", $OS) ) {
			$writesol = "Change the permissions on the <strong><font color=\"blue\">".$docfolder."</strong></font> folder so that php has write access.  You may need to contact your host inorder to do this.  After changing the permissions, press the button below to continue installation.";
		} else {
			$writesol = "Log in to your hosting account via FTP or a control panel, and change permissions on the <strong><font color=\"blue\">".$docfolder."</strong></font> folder to 777.  After changing the permissions, press the button below to continue installation.";
		} 
		$Info = "</em><strong><font color=\"red\">Unable to install! </strong></font> The folder, <strong><font color=\"blue\">".$docfolder."</strong></font>, must be writable inorder to install.<br><strong><font color=\"red\"><br>Solution:</strong></font> ".$writesol.".";
		$installform = "<table width=108 align=right><tr><td align=center valign=bottom style=\"font-size: 12px; font-family: Times New Roman;\">";
		$installform .= "<a href=\"http://".$thisdomain."/".$shellpath."\"><img src=\"http://info.soholaunch.com/images/installer/run_installation.gif\" width=106 height=109 style=\"border: 1px solid #FDB417;\"></a></td></tr></table>";	
		fclose($file);
	} else {
		fclose($file);
		$writable = "yes";
		$deleted = unlink("test.txt");
	}

	if ( eregi('SHELL_EXEC', $disabled) ) { 
		$Info = "</em><strong><font color=\"red\">&nbsp;&nbsp;Unable to install! </strong></font> The php command, <strong><font color=\"blue\">SHELL_EXEC </strong></font>has been disabled on this server.<br><br><strong><font color=\"#ffc417\">&nbsp;&nbsp;Solution: </strong></font>Remove the <strong><font color=\"blue\">SHELL_EXEC </strong></font>command from the disable_functions list in this Server's php.ini .  You may need to ask your Host to enable <font color=\"blue\"><strong>SHELL_EXEC</strong></font>.  Once <font color=\"blue\"><strong>SHELL_EXEC </strong></font>is enabled, reload this script.";
		$installform = "<table width=108 align=right><tr><td align=center valign=bottom style=\"font-size: 12px; font-family: Times New Roman;\">";
		$installform .= "<a href=\"http://".$thisdomain."/".$shellpath."\"><img src=\"http://info.soholaunch.com/images/installer/run_installation.gif\" width=106 height=109 style=\"border: 1px solid #FDB417;\"></a></td></tr></table>";	
	}

	if ( ini_get('safe_mode') == "1") { 
		$Info = "</em><strong><font color=\"red\">&nbsp;&nbsp;Unable to install! </strong></font> This server is Running PHP in <strong><font color=\"blue\">SAFE_MODE</font></strong>.  In order to Install and Use <strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong><strong><font color=\"blue\"> SAFE_MODE</font></strong> must be <strong><font color=\"blue\">OFF</font></strong>.<br><br>&nbsp;&nbsp;<font color=\"#ffc417\"><strong>Solution: </strong></font>Turn <strong><font color=\"blue\">SAFE_MODE</font></strong> off in this Server's php.ini .  You may need to ask your Host to do this.  Once <font color=\"blue\"><strong>SAFE_MODE </strong></font>is <font color=\"blue\"><strong>OFF </strong></font>, reload this script.";
		$installform = "<table width=108 align=right><tr><td align=center valign=bottom style=\"font-size: 12px; font-family: Times New Roman;\">";
		$installform .= "<a href=\"http://".$thisdomain."/".$shellpath."\"><img src=\"http://info.soholaunch.com/images/installer/run_installation.gif\" width=106 height=109 style=\"border: 1px solid #FDB417;\"></a></td></tr></table>";	
	}
##############

class file_download {
   var $remote = array(); // Remote file data
   var $local = array(); // Local file data
   var $msg; // Specific success/failure message
 
   // Break full path into element arrays
   //================================================
   function file_download($rempath, $locpath, $donow = "rock") {
      $this->remote['path'] = $rempath;
      $this->remote['dir'] = dirname($rempath);
      $this->remote['file'] = basename($rempath);
      $this->local['path'] = $locpath;
      $this->local['dir'] = dirname($locpath);
      $this->local['file'] = dirname($locpath);

      # Proceed with dl unless otherwise directed
      if ( $donow == "rock" ) {
         return $this->dlnow();
      }
   }

   function dlnow() {
      if ( !$fp1 = fopen($this->remote['path'],"r") ) {
         $this->msg = "Unable to open remote update file.  Check your server's firewall settings.";
         return false;
      }

      // create local file
      if ( !$fp2 = fopen($this->local['path'],"w") ) {
         $this->msg = "Unable to write files to server.  \n";
         $this->msg .= "Check the permissions on the <strong>[".$this->local['dir']."]</strong> folder.  The permissions should be set to 777 for installation.";
         return false;
      }

      // read remote and write to local
      while (!feof($fp1)) {
           $output = fread($fp1,1024);
           fputs($fp2,$output);
      }

      fclose($fp1);
      fclose($fp2);

      $this->msg = "Remote file downloaded successfully.";
      return true;
   }
}
//// End remote file class

if ( $_POST['todo'] == "getfile" )  {
   # Pull remote build info file
   ob_start();
   include("http://update.securexfer.net/public_builds/build.conf.php");
   $pubBuild = ob_get_contents();
   ob_end_clean();

   # Restore build info array
   $latest_build = unserialize($pubBuild);
   $tarcab =  "http://update.securexfer.net/windows_server/untar.cab";
	 $savetocab = $docroot."untar.cab";
   # Build involved directory paths
   $remotefile =  $latest_build['download_full'];
   $savetodir = $docroot."pro.tgz";
   $getfile = new file_download($remotefile, $savetodir);
	 
	if ( !$getfile->dlnow() ) {
      $extracttable = "<font color=red><strong>Error: </strong>".$getfile->msg."</font><br>";
	} else {	
		if ( eregi("WIN", $OS) ) {
				$getcab = new file_download($tarcab, $savetocab);

				if ( !$getcab->dlnow() ) {
					$extracttable = "<font color=red><strong>Error: </strong>".$getfile->msg."</font><br>";
   			} else {
   				shell_exec("MKDIR extract"); sleep("5");
          $expand = shell_exec("expand -r -F:*.* untar.cab extract\ "); sleep("5");
          
          if ( $expand != "" ) {
         		shell_exec("del /F /Q untar.cab"); sleep("5");
          } else {
          	$extracttable = "<font color=red><strong>Error: </strong>Unable to expand untar executables.  <br>Possible Solution: Make sure that PHP's user or usergroup has permission to execute C:\WINDOWS\System32\cmd.exe. Also make sure that the php command \"shell_exec\" is not disabled.  You may need to contact your host to do this.</font><br>";
          }      
          $extract = "";
          $extract = shell_exec("extract\gunzip.exe -d pro.tgz"); sleep("10");
          $extract = shell_exec('EXTRACT\tar.exe -xvf pro.tar'); sleep("10");          
          
          if ($extract != "" ) {
						$installform = "<table align=right><tr><td align=center valign=bottom>";
						$installform .= "<a href=/sohoadmin/index.php>";
						$installform .= "<img src=http://info.soholaunch.com/images/installer/run_installation2.gif  width=\"106\" height=\"109\" style=\"border: 1px solid #FDB417;\"></td></tr></table>";
						$extractlist = "</font><br><font size=\"3\" face=\"Times New Roman, Times, serif\" color=#FDB417><em><strong>Product Downloaded and Extracted Successfuly!</strong></em></font><br><font size=\"3\" face=\"Times New Roman, Times, serif\" color=\"#0006ef\"><strong>Files Extracted ...</font></strong>";
						$extracttable = "<div id=ouput style=\"height:126; width:426; z-index:5; overflow:auto;\"".$extractlist."<pre>".$extract."</pre></div>";
//						include('sohoadmin/program/includes/remote_actions/class-fsockit.php');
//					  $scData = array();
//		  		  $scData['HOSTNAME'] = php_uname(n);
//		 			  $scData['DOMAIN'] = $thisdomain;
//		  			$scData['OS'] = $OS;
//		  		  $scSocket = new fsockit("site.soholaunch.com", "/media/scriptinstalled.php", $scData);
//		   			$scRez = $scSocket->sockput();
//					  $my_result = split("-OUTPUT-", $scRez['raw']);											
						$Info = "</em><strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong> was successfully copied to your server.  Click the button below to continue to the final step of installation where you will enter your <strong><font color=blue>MYSQL</font></strong> database Name, username, and password.  <a href=\"http://forum.soholaunch.com/showthread.php?p=3#post3\">Click here for instructions on setting up a MYSQL Database.</a><br>";
						shell_exec("DEL /F /Q $savetodir"); sleep("5");
						shell_exec("DEL /F /Q pro.tar"); sleep("5");
						shell_exec("DEL /F /Q untar.cab"); sleep("5");
						shell_exec("RMDIR /S /Q extract"); sleep("5");
						shell_exec("DEL /F /Q $savetodir"); sleep("5");
						shell_exec("DEL /F /Q $shellpath");
					} else {
						$extracttable = "<font color=red><strong>Error: </strong>Unable to extract file. </font><br>";
					}
				}	   		
			}// End if Win
			
		if ( !eregi("WIN", $OS) ) { 		
			$extract = shell_exec("tar -xzvf $savetodir");
			
			if ( $extract != "" ) {
		    $installform = "<table align=right><tr><td align=center valign=bottom>";
		    $installform .= "<a href=/sohoadmin/index.php>";
		    $installform .= "<img src=http://info.soholaunch.com/images/installer/run_installation2.gif  width=\"106\" height=\"109\" style=\"border: 1px solid #FDB417;\"></td></tr></table>";
		    $extractlist = "</font><br><font size=\"3\" face=\"Times New Roman, Times, serif\" color=#FDB417><em><strong>Product Downloaded and Extracted Successfuly!</strong></em></font><br><font size=\"3\" face=\"Times New Roman, Times, serif\" color=\"#0006ef\"><strong>Files Extracted ...</font></strong>";
		    $extracttable = "<div id=ouput style=\"height:166; width:426; z-index:5; overflow:auto;\"".$extractlist."<pre>".$extract."</pre></div>";
//		    include('sohoadmin/program/includes/remote_actions/class-fsockit.php');
//			  $scData = array();
//  		  $scData['HOSTNAME'] = php_uname(n);
// 			  $scData['DOMAIN'] = $thisdomain;
//  			$scData['OS'] = $OS;
//  		  $scSocket = new fsockit("site.soholaunch.com", "/media/scriptinstalled.php", $scData);
//   			$scRez = $scSocket->sockput();
//			  $my_result = split("-OUTPUT-", $scRez['raw']);
		    $Info = "</em><strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong> was successfully copied to your server.  Click the button below to continue to the final step of installation where you will enter your <strong><font color=blue>MYSQL</font></strong> database Name, username, and password.  <a href=\"http://forum.soholaunch.com/showthread.php?p=3#post3\">Click here for instructions on setting up a MYSQL Database.</a><br>";
		    shell_exec("rm $savetodir");
		    shell_exec("rm $shellpath");
			} else {
			  $extracttable = "<font color=red><strong>Error: </strong> Unable to extract file. </font><br>";
			}
		}	
	}
}

?>
<body bgcolor="#000000">

<div id="please_wait" style="z-index: 2; display: none; position: absolute; top: 25%; left: 35%; width: 300px; height: 180px; border: 2px solid #FDB417; background-color:#ffffff; layer-background-color:#ffffff; visibility: visible;">
	<table bgcolor=white align="center" valign="bottom">
		<tr>
			<td align="center" valign="middle" bgcolor=white>
			<br><br><img align="absmiddle" src="http://info.soholaunch.com/images/installer/installing.gif"><br><br><font color=#FDB417><strong>This may take several minutes.</strong></font>
		</td>
		</tr>
	</table>
</div>

<form name="SMOKE" method="post" action="installsoholaunch.php">
<table align=center width="552">
	<tr>
		<td style="padding:4em 0em 0em 0em;" bgcolor=black align=center valign=middle>
			<table id="installer_screen" style="display: block; border: 2px solid #FDB417;" valign="bottom" align="CENTER" width="552" cellpadding="0" cellspacing="0" bgcolor="#FFFFFF">
			  <tr>
			    <td width="552" valign="bottom" align="right">
			      <table width=552 align=center border="0" cellspacing="0" cellpadding="0">
			        <tr>
			          <td colspan="1" style="padding:0px 6px 0px 6px; valign="bottom" height="61" bgcolor="#FFFFFF" align="LEFT"><a href="http://info.soholaunch.com" target="_blank"><img src="http://info.soholaunch.com/images/installer/logo-soholaunch.gif" width="232" hspace="0" height="61" vspace="0" valign="top" align="left" border="0"></a></td>
			        </tr>
			        <tr>
			          <td valign=bottom colspan="2" style="padding: 0em 8px 0em 8px;" height="74"><div align="left">&nbsp;&nbsp;<em><span style="font-size:12px;" font face="Times New Roman, Times, serif"><br> <? echo $Info; ?></span></td>
			        </tr>
			        <tr>
			          <td style="padding:0px 0px 4px 6px;" valign="bottom"><br><? echo $extracttable; ?></td>
			          <td style="padding:0px 6px 4px 0px;" valign="bottom" align="right"><? echo $installform; ?></td>
			        </tr>
			      </table>
			    </td>
			  </tr>
			</table>
		</td>
	</tr>
</table>
</form>
</body>
</html>
