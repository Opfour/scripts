<?php
error_reporting(E_PARSE);

$changeTo = getcwd();
$php_suexec = php_sapi_name();
$owner = $_GET['user'];
$domain = $_GET['domain'];
$doc_root = $_GET['doc_root'];

$rootUN = $_SERVER['REMOTE_USER'];


$dbinfofile = '/root/.my.cnf';
$rddbinfo=fopen($dbinfofile, "r");
$mysql_login_info = fread($rddbinfo, filesize($dbinfofile));
fclose($rddbinfo);
$mysql_ar = explode("\n", $mysql_login_info);

$getpass = str_replace('pass="', '', $mysql_ar['2']);
$getpass = eregi_replace('"$', '', $getpass);


$rootUN = 'root';
$rootPW = $getpass;
//		echo shell_exec('/scripts/mysqlpasswd root');
$link = mysql_connect("localhost", $rootUN, $rootPW);




if(!function_exists('scandir')) {
   function scandir($dir, $sortorder = 0) {
       if(is_dir($dir))        {
           $dirlist = opendir($dir);
           while( ($file = readdir($dirlist)) !== false) {
               if(!is_dir($file)) {
                   $files[] = $file;
               }
           }
           ($sortorder == 0) ? asort($files) : rsort($files); // arsort was replaced with rsort
           return $files;
       } else {
       return FALSE;
       break;
       }
   }
}


//if($_GET['info']!= ''){
//	include('functions/getlogin.php');
//	exit;
//}

if ($_SERVER['REMOTE_USER'] != "root") {
  echo "You are not root";
  exit;
}
    
//Try and open /etc/localdomains
$fp = @fopen("/etc/userdomains", "r");
if (!fp) {
  echo "Failed to read /etc/userdomains";
  exit();
}
  
# Pull remote build info file
ob_start();
	include_r("http://update.securexfer.net/public_builds/build.conf.php");
	$pubBuild = ob_get_contents();
ob_end_clean();

# Restore build info array
$latest_build = unserialize($pubBuild);
# Build involved directory paths
$remotefile =  $latest_build['download_full'];
if(!isset($_GET['doc_root'])){
	$savetoDir = "/home/".$_GET['user']."/public_html";
	$savetoFile = "/home/".$_GET['user']."/public_html/pro.tgz";
} else {
	$savetoDir = $_GET['doc_root'];
	$savetoFile = $_GET['doc_root']."/pro.tgz";
}

if(isset($_GET['domain']) && !isset($_GET['uninstall']) && !isset($_GET['fixPerms'])){   

	$testfile = "/home/".$owner."/public_html/test.php";
	$testUrl = "/home/".$owner."/public_html";  
  	
   exec('chown '.$owner.'.'.$owner.' '.$testfile);   
   $file = fopen($testfile, "w");
   $stuffs = '<?php';
   $stuffs .= "\n".'echo php_sapi_name();'."\n";
   $stuffs .= '?>';
   if(!fwrite($file, $stuffs)) {
      echo "can't write test file!";
   }
   fclose($file);

	exec('chown -R '.$owner.'.'.$owner.' '.$testUrl);
	exec('chmod -R 0755 '.$testUrl);
   ob_start();
   	if(!include_r("http://".$_SERVER['SERVER_NAME'].'/~'.$owner."/test.php")){
   	   //echo "Cant inc test.php contents...<br/>";
   	}
   	$php_suexec = ob_get_contents();
   ob_end_clean();
   
	$php_suexec = strtoupper($php_suexec);
   unlink($testfile);
   
	$settings_dir = $changeTo."/settings";
	$whichbuild = $settings_dir."/version_to_install.txt";
	
	if(!file_exists($whichbuild)){
		$whichbuildfile = fopen($whichbuild, "w");
		fwrite($whichbuildfile, "Stable");
		fclose($whichbuildfile);
		$_SESSION['version_to_install'] = 'Stable';
	}

	$whichbuildfile = fopen($whichbuild, "r");
	$whichbuildread = fread($whichbuildfile, filesize($whichbuild));
	fclose($whichbuildfile);
	$_SESSION['version_to_install'] = $whichbuildread;
   
	
	chdir($changeTo."/install_files");
	if($_SESSION['version_to_install'] != 'Latest'){
		$file = "pro.tgz";
	} else {
		$file = "probeta.tgz";
	}


	$newfile = $doc_root."/pro.tgz";
	if (!copy($file, $newfile)) {
	   echo "failed to copy $file...\n";
	}
	 
	chdir($doc_root); 
	$extract = shell_exec("tar -xzvf $newfile");
	
	if ( $extract != "" ) {
		$owngrpdir = $doc_root."/sohoadmin";
		unlink($newfile);
		
		###############################################################
		### Create DB
		###############################################################

		$randKey = randomkeys(12);
		$randKeyUser = randomkeys(3);

		$sqlUser = $owner."_soho".$randKeyUser;
		$sqlInsert = "create database ".$sqlUser;
		
		$dbusername = "soho".$randKeyUser;; 
		$dbpassword = $randKey;
		$dbname = "soho".$randKeyUser;
		
		
		if (!$link) {
			/////////////// cant connect to mysql as root
			$makedbstring="xml-api/cpanel?user=".$owner."&xmlin=%3Ccpanelaction%3E%3Cmodule%3EMysql%3C/module%3E%3Cfunc%3Eadddb%3C/func%3E%3Capiversion%3E1%3C/apiversion%3E%3Cargs%3E".$dbname."%3C/args%3E%3C/cpanelaction%3E";
			$makedbuser = "xml-api/cpanel?user=".$owner."&xmlin=%3Ccpanelaction%3E%3Cmodule%3EMysql%3C/module%3E%3Cfunc%3Eadduser%3C/func%3E%3Capiversion%3E1%3C/apiversion%3E%3Cargs%3E".$dbusername."%3C/args%3E%3Cargs%3E".$dbpassword."%3C/args%3E%3C/cpanelaction%3E";
			$grantdbprivs = "xml-api/cpanel?user=".$owner."&xmlin=%3Ccpanelaction%3E%3Cmodule%3EMysql%3C/module%3E%3Cfunc%3Eadduserdb%3C/func%3E%3Capiversion%3E1%3C/apiversion%3E%3Cargs%3E".$owner."_".$dbusername."%3C/args%3E%3Cargs%3E".$owner."_".$dbname."%3C/args%3E%3Cargs%3EALL%3C/args%3E%3C/cpanelaction%3E";
			
			echo "<iframe src=\"".$makedbstring."\" width=1PX height=1px frameborder=0 align=left scrolling=auto></iframe>";
			echo "<iframe src=\"".$makedbuser."\" width=1PX height=1px frameborder=0 align=left scrolling=auto></iframe>";
			echo "<iframe src=\"".$grantdbprivs."\" width=1PX height=1px frameborder=0 align=left scrolling=auto></iframe>";
		} else {

			mysql_query("$sqlInsert");
			mysql_query("grant all privileges on *.* to $sqlUser@localhost identified by '$randKey' with grant option");
		}

		


		###############################################################
		### END Create DB
		###############################################################
		
		###############################################################
		### Write isp.conf.php
		###############################################################
		
		# Passed vars from form
		if($_GET['sohouser'] != ''){
			$adminUser = $_GET['sohouser'];
		} else {
			$adminUser = "admin";
		}
		
		if($_GET['sohopass'] != ''){
			$adminPass = $_GET['sohopass'];
		} else {
			$adminPass = "admin";
		}

		
		//$dbname = $_GET['dbname'];
		//$dbuser = $_GET['uname'];
		//$dbpass = $_GET['pword'];
		//
		////****************************************************************************//
		//$ISP_DIR = $cpBASE."/frontend/".$cpTYPE."/cells/soholaunch";
		//$ISP_DIR = "/usr/local/cpanel/base/frontend/x/cells/soholaunch";
		chdir($changeTo);
		
		$ISPfilename = $changeTo."/isp.conf_base.php";
		$fd = fopen ($ISPfilename, "r");
			$ISPcontents = fread ($fd, filesize ($ISPfilename));
			$ISPcontents = str_replace("#THISIP#", $domain, $ISPcontents);
			$ISPcontents = str_replace("#DOCROOT#", $doc_root, $ISPcontents);
			$ISPcontents = str_replace("#DBUSERNAME#", $sqlUser, $ISPcontents);
			$ISPcontents = str_replace("#USERNAME#", $sqlUser, $ISPcontents);
			$ISPcontents = str_replace("#PASSWORD#", $randKey, $ISPcontents);
			$ISPcontents = str_replace("#LOGINUSER#", $adminUser, $ISPcontents);
			$ISPcontents = str_replace("#LOGINPASS#", $adminPass, $ISPcontents);
		fclose ($fd);
		
		chdir($doc_root);
		
		$FILE = "sohoadmin/config/isp.conf.php";
		$fd = fopen ($FILE, "w");
			fputs($fd, $ISPcontents);
		fclose($fd);
		
		$owngrpdir = $doc_root."/sohoadmin";
	   $sohoImages = $doc_root."/images";
	   $sohoMedia = $doc_root."/media";
		if(eregi("CGI", $php_suexec)){
			$chOwnSoho = exec("chown -R ".$owner.".".$owner." ".$doc_root);
			$chOwnSoho = exec("chmod -R 0755 ".$doc_root);
			$Info = "<strong><font color=\"#ffc417\">Permissions on (".$_GET['domain'].") were set to:</font></strong><strong><br/>755<br/>Owner:".$owner."<br/>Group:".$owner."</strong><br>";
		}else{
			$chOwnSoho = exec("chown -R nobody.".$owner." ".$doc_root);
			$chOwnSoho = exec("chown -R ".$owner.".".$owner." ".$doc_root."/cgi-bin");
			$chOwnSoho = exec("chown ".$owner.".".$owner." ".$doc_root."/.htaccess");
			$chOwnSoho = exec("chmod -R 0775 ".$doc_root);
			$chOwnSoho = exec("chmod -R 0755 ".$doc_root."/cgi-bin");
			$chOwnSoho = exec("chmod 0755 ".$doc_root."/.htaccess");
		}
		
		###############################################################
		### END Create isp.conf.php
		###############################################################
		$d_ar = explode('/', $doc_root);		
		
		$Info = "<p><strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong> was successfully installed on (".$_GET['domain'].").<br>";
		$Info .= "<br/><strong><font color=\"#000000\">Login URL: </strong><a style=\"text-decoration:none;\" href=\"http://".$_GET['domain']."/sohoadmin/index.php\" target=\"_BLANK\">http://".$_GET['domain']."/sohoadmin/index.php</a> \n<br>";
		if(count($d_ar) > 4){
			$Info .= "<strong><font color=\"#000000\">Temp URL: </strong><a style=\"text-decoration:none;\" href=\"http://".$_SERVER['HTTP_HOST']."/~".$owner."/".$d_ar['4']."/sohoadmin/index.php\" target=\"_BLANK\">http://".$_SERVER['HTTP_HOST']."/~".$owner."/".$d_ar['4']."/sohoadmin/index.php</a>\n<br>";
		} else {
			$Info .= "<strong><font color=\"#000000\">Temp URL: </strong><a style=\"text-decoration:none;\" href=\"http://".$_SERVER['HTTP_HOST']."/~".$owner."/sohoadmin/index.php\" target=\"_BLANK\">http://".$_SERVER['HTTP_HOST']."/~".$owner."/sohoadmin/index.php</a>\n<br>";
		}
		$Info .= "<strong><font color=\"#000000\">Soholaunch Username: </strong>".$_GET['sohouser']." \n<br>";
		$Info .= "<strong><font color=\"#000000\">Soholaunch Password: </strong>".$_GET['sohopass']." \n<br></p>";

	} else {
		$Info = "<font color=red><strong>Error: </strong> Unable to extract file. </font><br>";
	}

	
}elseif(isset($_GET['uninstall'])){
//	echo "Uninstalling!";
//	echo "(".$doc_root.")<br/>";
$doc_root = $_GET['doc_root'];
$user = $_GET['user'];
	chdir($doc_root);
	//Try and open /var/cpanel/users/ file for user
	$fp = @fopen("sohoadmin/config/isp.conf.php", "r");
	 
	if (!fp) {
		echo "Failed to read sohoadmin/config/isp.conf.php";
		exit();
	}
	
	$LISTaccounts = fread($fp, filesize("sohoadmin/config/isp.conf.php"));
	fclose($fp);
	
	$joesAccountList = JoesAccounts($LISTaccounts);

	foreach($joesAccountList as $var=>$val){
		if($var == "db_name"){
			$dbName = $joesAccountList['db_name'];
			$deletedb = "xml-api/cpanel?user=".$owner."&db=".$owner."_".$dbName."&xmlin=%3Ccpanelaction%3E%3Cmodule%3EMysql%3C/module%3E%3Cfunc%3Edeldb%3C/func%3E%3Capiversion%3E1%3C/apiversion%3E%3Cargs%3E".$owner."_".$dbName."%3C/args%3E%3C/cpanelaction%3E";		
			echo "<iframe src=\"".$deletedb."\" width=1PX height=1px frameborder=0 align=left scrolling=auto></iframe>";
		}
	}

	$delFiles = "sohoadmin, images, import, media, tCustom, template, shopping, subscription, data.sql, can_prov.dat, currentuser.log, index.php, pgm-authenticate.php, pgm-auto_menu.php, ";
	$delFiles .= "pgm-blog_display.php,  pgm-blog_styles.php, pgm-cal-confirm.php, pgm-cal-details.inc.php, pgm-cal-monthview.php, pgm-cal-submitevent.inc.php, ";
	$delFiles .= "pgm-cal-system.php, pgm-cal-weekview.php, pgm-download_media.php, pgm-email_friend.php, pgm-faq_display.php, ";
	$delFiles .= "pgm-form_submit.php, pgm-get_password.php, pgm-numusers.php, pgm-page_templates.php, pgm-photo_album.php, ";
	$delFiles .= "pgm-print_page.php, pgm-promo_boxes.php, pgm-realtime_builder.php, pgm-rememberme.php, pgm-secure_login.php, ";
	$delFiles .= "pgm-secure_manage.php, pgm-secure_remember.php, pgm-single_sku.php, pgm-site_config.php, pgm-site_stats.inc.php, ";
	$delFiles .= "pgm-tracking.php, pgm-view_video.php, pgm-write_review.php, runtime.css, securelogin.gif, sort_image.gif, ";
	$delFiles .= "spacer.gif, subscription, under_construction.gif, us_states.dat, vicon.gif, pgm-photo_album-single.php, robots.txt";

	$sohoDir = split(", ", $delFiles);

	foreach($sohoDir as $var => $val){
		$delThis = $doc_root."/".$val;
		remdir($delThis);
	}
	
	$Info = "<strong><font color=\"#ffc417\">Soholaunch Pro Edition</font></strong> was successfully uninstalled from (".$_GET['domain'].").<br>";
	
}elseif(isset($_GET['fixPerms'])){
   
   $testfile = "/home/".$owner."/public_html/test.php";
   $testUrl = "/home/".$owner."/public_html";  
   exec('chown '.$owner.'.'.$owner.' '.$testfile);
   
   
   if(!is_file($testfile)){
      //echo "cant find test.php... creating...";
      $file = fopen($testfile, "w");
      $stuffs = '<?php';
      $stuffs .= "\n".'echo php_sapi_name();'."\n";
      $stuffs .= '?>';
      if(!fwrite($file, $stuffs)) {
      	echo "can't write test file!";
      }
      fclose($file);
   }
	exec('chown -R '.$owner.'.'.$owner.' '.$testUrl);
	exec('chmod -R 0755 '.$testUrl);

   ob_start();
   	if(!include_r("http://".$_SERVER['SERVER_NAME'].'/~'.$owner."/test.php")){
   	   //echo "Cant inc test.php contents...<br/>";
   	}
   	$php_suexec = ob_get_contents();
   ob_end_clean();
   
	$php_suexec = strtoupper($php_suexec);
   unlink($testfile);

	$owngrpdir = $doc_root."/sohoadmin";
   $sohoImages = $doc_root."/images";
   $sohoMedia = $doc_root."/media";
		if(eregi("CGI", $php_suexec)){
			$chOwnSoho = exec("chown -R ".$owner.".".$owner." ".$doc_root);
			$chOwnSoho = exec("chmod -R 0755 ".$doc_root);
			$Info = "<strong><font color=\"#ffc417\">Permissions on (".$_GET['domain'].") were set to:</font></strong><strong><br/>755<br/>Owner:".$owner."<br/>Group:".$owner."</strong><br>";
		}else{
			$chOwnSoho = exec("chown -R nobody.".$owner." ".$doc_root);
			$chOwnSoho = exec("chown -R ".$owner.".".$owner." ".$doc_root."/cgi-bin");
			$chOwnSoho = exec("chown ".$owner.".".$owner." ".$doc_root."/.htaccess");
			$chOwnSoho = exec("chmod -R 0775 ".$doc_root);
			$chOwnSoho = exec("chmod -R 0755 ".$doc_root."/cgi-bin");
			$chOwnSoho = exec("chmod 0755 ".$doc_root."/.htaccess");
			$Info = "<strong><font color=\"#ffc417\">Permissions on (".$_GET['domain'].") were set to:</font></strong><strong><br/>775<br/>Owner:nobody<br/>Group:".$owner."</strong><br>";
		}
	
}else{		
	# Show Domain List
	$LISTaccounts = fread($fp, filesize("/etc/userdomains"));
	fclose($fp);
	
	$domainlist = accountsLIST($LISTaccounts);
		
$DOMlist = "<script language=\"javascript\">\n";
$DOMlist .= "function promptuser(dadomain,dauser){ \n";
$DOMlist .= "	var dausername=window.prompt(\"Soholaunch Username for \"+dadomain, dauser);\n";
$DOMlist .= "	if(dausername.length < 2){\n";
$DOMlist .= "		return promptuser(dadomain, dauser);\n";
$DOMlist .= "	} else {\n";
$DOMlist .= "		return dausername;\n";
$DOMlist .= "	}\n";
$DOMlist .= "} \n";

$DOMlist .= "function promptpass(dadomain,dauser){ \n";
$DOMlist .= "	var dapass=window.prompt(\"Soholaunch Password for \"+dadomain);\n";
$DOMlist .= "	if(dapass.length < 2){\n";
$DOMlist .= "		return promptpass(dadomain, dauser);\n";
$DOMlist .= "	} else {\n";
$DOMlist .= "		return dapass;\n";
$DOMlist .= "	}\n";
$DOMlist .= "} \n";

$DOMlist .= "function install(domain,user,docroot){ \n";
$DOMlist .= "	var theuser=''\n";
$DOMlist .= "	var thepass=''\n";
$DOMlist .= "	theuser = promptuser(domain, user);\n";
$DOMlist .= "	thepass = promptpass(domain, user);\n";

$DOMlist .= "	var createurl = \"soholaunch.php?domain=\"+domain+\"&user=\"+user+\"&doc_root=\"+docroot+\"&sohouser=\"+theuser+\"&sohopass=\"+thepass;\n";
$DOMlist .= "	window.location = createurl; \n";

$DOMlist .= "} \n";


$DOMlist .= "function uninstall(domain,url){ \n";

$DOMlist .= "var answer = confirm(\"Are you sure that you want to delete this the Soholaunch installation on \"+domain+\"?\")\n";
$DOMlist .= "	if (answer){\n";
$DOMlist .= "		window.location = url;\n";
$DOMlist .= "	} else {\n";
//$DOMlist .= "		window.location = \"#\";\n";
$DOMlist .= "\n";
$DOMlist .= "	}\n";

$DOMlist .= "} \n";
$DOMlist .= "</script>\n";

	//echo testArray($S_localdomains);

		ksort($domainlist);
	$dom1 = '';
	$dom2 = '';
	foreach($domainlist as $var=>$val){
		$doc_root = is_soho_sub($val, $var);
//echo $var." ".$val."<br/>";
		//$doc_root = '/home/'.$val.'/public_html';
		$val_ar['0']=$val;
		$val_ar['1']=$doc_root;
		if($doc_root != ''){
			if(is_soho($doc_root)){
				$inst_text = "Installed!";
				$dom1[$var]=$val_ar;
			}else{
				$inst_text = "Not Installed!";
				$dom2[$var]=$val_ar;
			}
		}

	}
$doc_root = '';
//$DOMlist .= "<table align=\"center\" valign=top bgcolor=\"#4F6C7F\" style=\"border: 1px outset #999999; cellpadding=5; cellspacing=0; font: arial; font-weight: bold; width:95%;\">";


	$DOMlist .= "<table align=\"center\" valign=top bgcolor=\"#4F6C7F\" style=\"border: 1px outset #999999; cellpadding=5; cellspacing=0; font: arial; font-weight: bold; width:97%;\">";

	$DOMlist .= "<tr align=\"left\">\n	<td align=left colspan=\"4\"  class=\"domRow\" bgcolor=\"white\" color=\"black\" style=\"padding-left: 5px; padding-right: 5px;\"><strong>Soholaunch Not Installed</strong></td></tr>\n";
	
	$DOMlist .= "<tr align=left>\n";
	$DOMlist .= "	<td align=\"left\" class=\"domRow\" bgcolor=\"#ffffff\" style=\"border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold; padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		<font color=black>Domain Name</font>\n";
	$DOMlist .= "	</td>\n";

	$DOMlist .= "	<td align=\"left\" class=\"domRow\" bgcolor=\"#FFFFFF\" style=\"width:150px; border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold; padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		<font color=black>Username</font>\n";
	$DOMlist .= "	</td>\n";
	$DOMlist .= "	<td align=\"left\" class=\"domRow\" bgcolor=\"#FFFFFF\" style=\"width:150px; border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold; padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		<font color=black>Status</font>\n";
	$DOMlist .= "	</td>\n";
	$DOMlist .= "	<td align=\"center\" class=\"domRow\" bgcolor=\"#FFFFFF\" style=\"width:100px; border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold; padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		Action\n";
	$DOMlist .= "	</td>\n";
	$DOMlist .= "</tr>";
	

	
	foreach($dom2 as $var=>$val){
	//if($inst_text == "Installed!"){
		$doc_root = $val['1'];
		//echo "<br/>";
		//$doc_root = '/home/'.$val.'/public_html';
		
		if ( $bg == "#cbe0cf" ) { $bg = "#FFFFFF"; } else { $bg = "#cbe0cf"; }
		//if ( $bg2 == "#FFFFFF" ) { $bg2 = "#215891"; } else { $bg2 = "#FFFFFF"; }
		$bg2 == "#000000";
		$DOMlist .= "<tr align=\"left\">\n";
		$DOMlist .= "	<td align=left class=\"domRow\" bgcolor=\"".$bg."\" style=\"\">\n";
		$DOM1='';
		$DOM2='';
	//	if($inst_text == "Installed!"){
		//	$DOMlist .= "		<FONT color=\"#000000\">".$var."</font><br/>\n			<a href=\"soholaunch.php?domain=".$var."&user=".$val."&doc_root=".$doc_root."&fixPerms=1\">Fix Permissions</a>\n";
		//}else{
			$DOMlist .= "		<FONT color=\"#000000\">".$var."</font>\n";
	//	}
		$DOMlist .= "	</td>\n";
		$DOMlist .= "	<td align=\"left\" valign=\"top\" class=\"domRow\" style=\"width:150px; \" bgcolor=\"".$bg."\">\n";
		$DOMlist .= "		<FONT color=\"#000000\">".$val['0']."</font>\n";
		$DOMlist .= "	</td>\n";
		$DOMlist .= "	<td align=left class=\"domRow\" bgcolor=\"".$bg."\" style=\"width:150px; font-weight: normal;\">\n";
		$DOMlist .= "		<font color=\"#BF001A\"><em>Not Installed!</em></font>\n";
		$DOMlist .= "	</td>\n";
		$DOMlist .= "	<td align=\"center\" class=\"domRowInstall\" bgcolor=\"#ffffff\" style=\"width:100px; padding-left: 5px; padding-right: 5px;\">\n";
	//	if($inst_text == "Installed!"){
		//	$DOMlist .= "		<font color=\"#BF001A\"><em><a href=\"#\" onclick=\"uninstall('".$var."', 'soholaunch.php?domain=".$var."&user=".$val['0']."&doc_root=".$doc_root."&uninstall=1');\"> Uninstall </a></em></font>\n";
			//$DOMlist .= "		<font color=\"#BF001A\"><em><a href=\"soholaunch.php?domain=".$var."&user=".$val['0']."&doc_root=".$doc_root."&uninstall=1\"> Uninstall </a></em></font>\n";
	//	}else{
	if($_SESSION['password_option'] == 'set'){
		$DOMlist .= "		<font color=\"#BF001A\"><em><a href=\"soholaunch.php?domain=".$var."&user=".$val['0']."&doc_root=".$doc_root."&sohouser=".$_SESSION['default_user']."&sohopass=".$_SESSION['default_pass']."\"> Install Pro </a></em></font>\n";
	} else {
		$DOMlist .= "		<font color=\"#BF001A\"><em><a href=\"#\" onclick=\"install('".$var."', '".$val['0']."', '".$doc_root."')\"> Install Pro </a></em></font>\n";
	}
		
			//$DOMlist .= "		<font color=\"#BF001A\"><em><a href=\"soholaunch.php?domain=".$var."&user=".$val['0']."&doc_root=".$doc_root."\"> Install Pro </a></em></font>\n";
			//$DOMlist .= "		<a href=\"#\"> <font SIZE=2px color=\"#BF001A\">Install Pro</font> </a>\n";
	//	}
		$DOMlist .= "	</td>\n";
		$DOMlist .= "</tr>\n";
		
	}
	$DOMlist .= "</TABLE>";
	
	$DOMlist .= "<table align=\"center\" valign=top bgcolor=\"#4F6C7F\" style=\"border: 1px outset #999999; cellpadding=5; cellspacing=0; font: arial; font-weight: bold; width:97%;\">";

	$DOMlist .= "<tr align=\"left\">\n	<td colspan=\"5\" align=left class=\"domRow\" bgcolor=\"white\" color=\"black\" style=\"padding-left: 5px; padding-right: 5px;\"><strong>Soholaunch Is Installed</strong></td></tr>\n";
	
	$DOMlist .= "<tr align=left>\n";
	$DOMlist .= "	<td align=\"left\" class=\"domRow\" bgcolor=\"#ffffff\" style=\"border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold; padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		<font color=black>Domain Name</font>\n";
	$DOMlist .= "	</td>\n";

	$DOMlist .= "	<td align=\"left\" class=\"domRow\" bgcolor=\"#FFFFFF\" style=\"width:150px; border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold; padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		<font color=black>Username</font>\n";
	$DOMlist .= "	</td>\n";
	$DOMlist .= "	<td align=\"left\" class=\"domRow\" bgcolor=\"#FFFFFF\" style=\"width:150px; border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold; padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		<font color=black>Status</font>\n";
	$DOMlist .= "	</td>\n";
	
	$DOMlist .= "	<td align=\"left\" class=\"domRow\" bgcolor=\"#FFFFFF\" style=\"width:150px; border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold; padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		<font color=black>Information</font>\n";
	$DOMlist .= "	</td>\n";
	$DOMlist .= "	<td align=\"center\" class=\"domRow\" bgcolor=\"#FFFFFF\" style=\"width:100px; border-bottom: 1px solid #999999; font: 13px arial; font-weight: bold;padding-left: 5px; padding-right: 5px; font-family:\"Trebuchet MS\",Verdana,sans-serif; font-size:1em;\">\n";
	$DOMlist .= "		Action\n";
	$DOMlist .= "	</td>\n";
	$DOMlist .= "</tr>";
	
	

	foreach($dom1 as $var=>$val){
	//if($inst_text == "Installed!"){
		$doc_root = $val['1'];
		if ( $bg == "#cbe0cf" ) { $bg = "#FFFFFF"; } else { $bg = "#cbe0cf"; }
		//if ( $bg2 == "#FFFFFF" ) { $bg2 = "#215891"; } else { $bg2 = "#FFFFFF"; }
		$bg2 == "#000000";
		
		$DOMlist .= "<tr align=\"left\">\n";
		$DOMlist .= "	<td align=left style=\"width:300px; \" class=\"domRow\" bgcolor=\"".$bg."\" >\n";
		$DOM1='';
		$DOM2='';
	//	if($inst_text == "Installed!"){
			$DOMlist .= "		<FONT color=\"#000000\">".$var."</font><br/>\n			<a href=\"soholaunch.php?domain=".$var."&user=".$val['0']."&doc_root=".$doc_root."&fixPerms=1\">Fix Permissions</a>\n";
		//}else{
		//	$DOMlist .= "		<FONT color=\"#000000\">".$var."</font>\n";
	//	}
		$DOMlist .= "	</td>\n";
		$DOMlist .= "	<td align=\"left\" valign=\"top\" class=\"domRow\" style=\"width:150px; \" bgcolor=\"".$bg."\">\n";
		$DOMlist .= "		<FONT color=\"#000000\">".$val['0']."</font>\n";
		$DOMlist .= "	</td>\n";
		$DOMlist .= "	<td align=left class=\"domRow\" bgcolor=\"".$bg."\" style=\"width:100px; font-weight: normal;\">\n";
		$DOMlist .= "		<font color=\"green\"><em>Installed!</em></font>\n";
		$DOMlist .= "	</td>\n";
		
		$DOMlist .= "	<td align=left class=\"domRow\" bgcolor=\"".$bg."\" style=\"width:100px; font-weight: normal;\">\n";
		$DOMlist .= "	<font color=\"green\"><strong><a style=\"cursor:pointer;\" onmouseover=\"style.cursor='pointer'\" onclick=\"openInfoDialogINFO('".$var."', '".$val['0']."', '".$val['1']."');\"\">Information</a></strong></font>\n";
		$DOMlist .= "	</td>\n";
		//?todomains=1&info=".$val."
	
		$DOMlist .= "	<td align=\"center\" class=\"domRowInstall\" bgcolor=\"#ffffff\" style=\"width:90px; padding-left: 5px; padding-right: 5px;\">\n";
	//	if($inst_text == "Installed!"){
			$DOMlist .= "		<font color=\"#BF001A\"><em><a href=\"#\" style=\"color:#BF001A;\" onclick=\"uninstall('".$var."', 'soholaunch.php?domain=".$var."&user=".$val['0']."&doc_root=".$doc_root."&uninstall=1');\"> Uninstall </a></em></font>\n";
			//$DOMlist .= "		<font color=\"#BF001A\"><em><a href=\"soholaunch.php?domain=".$var."&user=".$val."&doc_root=".$doc_root."&uninstall=1\"> Uninstall </a></em></font>\n";
//		}else{
//			$DOMlist .= "		<font color=\"#BF001A\"><em><a href=\"soholaunch.php?domain=".$var."&user=".$val."&doc_root=".$doc_root."\"> Install Pro </a></em></font>\n";
//			//$DOMlist .= "		<a href=\"#\"> <font SIZE=2px color=\"#BF001A\">Install Pro</font> </a>\n";
//		}
		$DOMlist .= "	</td>\n";
		$DOMlist .= "</tr>\n";
		
	}
	

	$DOMlist .= "</TABLE>";
	//echo $DOMlist;
}

?>