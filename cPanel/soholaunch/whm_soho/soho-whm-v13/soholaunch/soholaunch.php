<?php
error_reporting(E_PARSE);
session_start();
//----------------------------------------------------------------------------//
    set_time_limit (                        864000 ) ;
    ini_set        ( 'max_execution_time' , 864000 ) ;
//----------------------------------------------------------------------------//
$changeTo = getcwd();
chdir($changeTo);
include("/usr/local/cpanel/whostmgr/docroot/cgi/soholaunch/functions/shared_functions.php");
include("/usr/local/cpanel/whostmgr/docroot/cgi/soholaunch/functions/class-file_download.php");


if(!is_dir($changeTo."/install_files")){
   mkdir($changeTo."/install_files");
}

$php_suexec = php_sapi_name();

//# Pull remote build info file
ob_start();
	include_r("http://update.securexfer.net/public_builds/build.conf.php");
	$pubBuild = ob_get_contents();
ob_end_clean();

# Restore build info array
$latest_build = unserialize($pubBuild);

$currentStable =  $latest_build['build_name'];
$remotefile =  $latest_build['download_full'];

ob_start();
	include_r("http://update.securexfer.net/public_builds/api-build_info-latest.php");
	$betaBuild = ob_get_contents();
ob_end_clean();
$beta_build = unserialize($betaBuild);	

if($beta_build == ''){
	$betaStable =  $latest_build['build_name'];
	$remotebetafile =  $latest_build['download_full'];
} else {
	# Restore build info array
	
	$betaStable =  $beta_build['build_name'];
	$remotebetafile =  $beta_build['download_full'];
}


$tabledisplay = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\"> \n";
$tabledisplay .= "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\"> \n";
$tabledisplay .= "	<head> \n";
$tabledisplay .= "        <title>Soholaunch Pro Edition WHM Installer</title>	 \n";
$tabledisplay .= "        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\"> \n";
$tabledisplay .= "        <link rel=\"stylesheet\" type=\"text/css\" href=\"soholaunch.css\"> \n";
$tabledisplay .= "<script language=\"javascript\"> \n";
$tabledisplay .= "function $() { \n";
$tabledisplay .= "  var elements = new Array(); \n";
$tabledisplay .= "  for (var i = 0; i < arguments.length; i++) { \n";
$tabledisplay .= "    var element = arguments[i]; \n";
$tabledisplay .= "    if (typeof element == 'string') \n";
$tabledisplay .= "      element = document.getElementById(element); \n";
$tabledisplay .= "    if (arguments.length == 1) \n";
$tabledisplay .= "      return element; \n";
$tabledisplay .= "    elements.push(element); \n";
$tabledisplay .= "  } \n";
$tabledisplay .= "  return elements; \n";
$tabledisplay .= "} \n";
$tabledisplay .= "function showDis(showLayer){ \n";
$tabledisplay .= "	//alert(showLayer);	 \n";
$tabledisplay .= "	if(showLayer != 'intro'){ \n";
$tabledisplay .= "		$('intro').style.display='none'; \n";
$tabledisplay .= "		$('introBtn').className=''; \n";
$tabledisplay .= 	"} \n";
$tabledisplay .= "	if(showLayer != 'settings'){ \n";
$tabledisplay .= "		$('settings').style.display='none'; \n";
$tabledisplay .= "		$('settingsBtn').className=''; \n";
$tabledisplay .= "	} \n";
$tabledisplay .= "	if(showLayer != 'domains'){ \n";
$tabledisplay .= "		$('domains').style.display='none'; \n";
$tabledisplay .= "		$('domainsBtn').className=''; \n";
$tabledisplay .= "} \n";
$tabledisplay .= "	$(showLayer).style.display='block'; \n";
$tabledisplay .= "	$(showLayer+'Btn').className='Blue'; \n";
$tabledisplay .= "} \n";
$tabledisplay .= "</script> \n";

$tabledisplay .= "<script language=\"javascript\">\n";
$tabledisplay .= "function checkfinished() { \n";
$tabledisplay .= "	Dialog.closeInfo(); \n";
$tabledisplay .= "	location.href=\"soholaunch.php\"; \n";		
$tabledisplay .= "} \n";

$tabledisplay .= "function checkfinishedWHM() { \n";
$tabledisplay .= "	Dialog.closeInfo(); \n";
$tabledisplay .= "	location.href=\"soholaunch.php?SohoWhmUpdate=finish\"; \n";		
$tabledisplay .= "} \n";

$tabledisplay .= "</script>\n";
$tabledisplay .= "<script type=\"text/javascript\" src=\"window/prototype.js\"></script> \n";
$tabledisplay .= "<script type=\"text/javascript\" src=\"window/window.js\"></script> \n";
$tabledisplay .= "<script type=\"text/javascript\" src=\"window/effects.js\"></script> \n";
$tabledisplay .= "<link href=\"window/default.css\" rel=\"stylesheet\" type=\"text/css\"></link> \n";
$tabledisplay .= "<link href=\"window/alert_lite.css\" rel=\"stylesheet\" type=\"text/css\"></link> \n";
$tabledisplay .= "<script language=\"javascript\">\n";
$tabledisplay .= "function openInfoDialog() {\n";
$tabledisplay .= " Dialog.info(\"<br>Updating Soholaunch Build Files to ".$currentStable." & ".$betaStable." ...\", {windowParameters: {className: \"alert_lite\",width:550, height:100}, showProgress: true});\n";
$tabledisplay .= "}\n";
$tabledisplay .= "function openInfoDialogWHM() {\n";
$tabledisplay .= " Dialog.info(\"<br>Updating Soholaunch's WHM Pro Edition Installer ...\", {windowParameters: {className: \"alert_lite\",width:450, height:100}, showProgress: true});\n";
$tabledisplay .= "}\n";

$tabledisplay .= "function openInfoDialogINFO(domain, user, docroot) {\n";
//$tabledisplay .= " alert('domain - '+domain)\n";
//$tabledisplay .= " alert('user - '+user)\n";
$tabledisplay .= " Dialog.info(\"Getting domain info ...\", {windowParameters: {className: \"alert_lite\",width:350, height:100}, showProgress: false});\n";
$tabledisplay .= " ajaxDo('ajax_div.php?cpanel_user='+user+'&cpanel_domain='+domain+'&doc_root='+docroot, 'modal_dialog_content');\n";
//$tabledisplay .= "   setTimeout('Dialog.closeInfo();', 2000)\n";
$tabledisplay .= "}\n";

$tabledisplay .= "//---------------------------------------------------------------------------------------------------------\n";
$tabledisplay .= "//      _      _   _   __  __\n";
$tabledisplay .= "//     /_\  _ | | /_\  \ \/ /\n";
$tabledisplay .= "//    / _ \| || |/ _ \  >  <\n";
$tabledisplay .= "//   /_/ \_\\__//_/ \_\/_/\_\\n";
$tabledisplay .= "//\n";
$tabledisplay .= "//---------------------------------------------------------------------------------------------------------\n";
$tabledisplay .= "// The following script (as commonly seen in other AJAX javascripts) is used to detect which browser the client is using.\n";
$tabledisplay .= "// If the browser is Internet Explorer we make the object with ActiveX.\n";
$tabledisplay .= "// (note that ActiveX must be enabled for it to work in IE)\n";
$tabledisplay .= "function makeObject() {\n";
$tabledisplay .= "   var x;\n";
$tabledisplay .= "   var browser = navigator.appName;\n";
$tabledisplay .= "\n";
$tabledisplay .= "   if ( browser == \"Microsoft Internet Explorer\" ) {\n";
$tabledisplay .= "      x = new ActiveXObject(\"Microsoft.XMLHTTP\");\n";
$tabledisplay .= "   } else {\n";
$tabledisplay .= "      x = new XMLHttpRequest();\n";
$tabledisplay .= "   }\n";
$tabledisplay .= "\n";
$tabledisplay .= "   return x;\n";
$tabledisplay .= "}\n";
$tabledisplay .= "\n";
$tabledisplay .= "// The javascript variable 'request' now holds our request object.\n";
$tabledisplay .= "// Without this, there's no need to continue reading because it won't work ;)\n";
$tabledisplay .= "var request = makeObject();\n";
$tabledisplay .= "\n";
$tabledisplay .= "function ajaxDo(qryString, boxid) {\n";
$tabledisplay .= "   //alert(qryString+', '+boxid);\n";
$tabledisplay .= "\n";
$tabledisplay .= "   rezBox = boxid; // Make global so parseInfo can get it\n";
$tabledisplay .= "\n";
$tabledisplay .= "   // The function open() is used to open a connection. Parameters are 'method' and 'url'. For this tutorial we use GET.\n";
$tabledisplay .= "   request.open('get', qryString);\n";
$tabledisplay .= "\n";
$tabledisplay .= "   // This tells the script to call parseInfo() when the ready state is changed\n";
$tabledisplay .= "   request.onreadystatechange = parseInfo;\n";
$tabledisplay .= "\n";
$tabledisplay .= "   // This sends whatever we need to send. Unless you're using POST as method, the parameter is to remain empty.\n";
$tabledisplay .= "   request.send('');\n";
$tabledisplay .= "\n";
$tabledisplay .= "}\n";
$tabledisplay .= "\n";
$tabledisplay .= "function parseInfo() {\n";
$tabledisplay .= "   // Loading\n";
$tabledisplay .= "   if ( request.readyState == 1 ) {\n";
$tabledisplay .= "      document.getElementById(rezBox).innerHTML = 'Loading...';\n";
$tabledisplay .= "   }\n";
$tabledisplay .= "\n";
$tabledisplay .= "   // Finished\n";
$tabledisplay .= "   if ( request.readyState == 4 ) {\n";
$tabledisplay .= "      var answer = request.responseText;\n";
$tabledisplay .= "      document.getElementById(rezBox).innerHTML = answer;\n";
$tabledisplay .= "   }\n";
$tabledisplay .= "}\n";


// End Ajax


$tabledisplay .= "</script>\n";
$tabledisplay .= "	</head> \n";

# Build involved directory paths
$saveto = $changeTo."/install_files/pro.tgz";
$savetodir = $changeTo."/install_files";

$savetobeta = $changeTo."/install_files/probeta.tgz";

//echo "remote file(".$remotefile.")<br/>";
//echo "save to(".$saveto.")<br/>";
$settings_dir = $changeTo."/settings";
if(!is_dir($settings_dir)){
	mkdir($settings_dir, 0755);
}

//download version
$buildfile = $settings_dir."/build_name.txt";
$file = fopen($buildfile, "r");
$buildcomp = fread($file, filesize($buildfile));
fclose($file);

$buildfilebeta = $settings_dir."/build_name_beta.txt";
$file = fopen($buildfilebeta, "r");
$buildcompbeta = fread($file, filesize($buildfilebeta));
fclose($file);

ob_start();
	include_r("http://update.securexfer.net/panel_files/soho-whm-build.conf.php");
	$whmvers = ob_get_contents();
ob_end_clean();

$whmvers_arr = explode(';', $whmvers);
$whmlink = basename($whmvers_arr['1']);

$whmfile = $settings_dir."/whm_vers.txt";
$wfile = fopen($whmfile, "r");
$whmconf = fread($wfile, filesize($whmfile));
fclose($wfile);
$whmconf_arr = explode(';', $whmconf);

if(!file_exists($whmfile)){
	unlink($whmfile);
	$wfile = fopen($whmfile, "w");
	fwrite($wfile, $whmvers);
	fclose($wfile);
	exec("chmod 0755 ".$whmfile);
}

//echo $whmconf."<br/>".$whmvers;
//exit;

$whm_new_file = '/usr/local/cpanel/whostmgr/docroot/cgi/whm-new-sohoinstall.tgz';

if($_GET['SohoWhmUpdate'] == 'yes'){
	$tabledisplay .= "<body style=\"background-color:#FFFFFF;\" onLoad=\"window.setTimeout('checkfinishedWHM()', 1500);\"> \n";
	$tabledisplay .= "<script language=\"javascript\"> \n";
	$tabledisplay .= " openInfoDialogWHM(); \n";
	$tabledisplay .= "</script> \n";
	$tabledisplay .= "</body> \n";
	echo $tabledisplay .= "</html> \n";
	unlink($whmfile);
	$wfile = fopen($whmfile, "w");
	fwrite($wfile, $whmvers);
	fclose($wfile);
	unlink($whm_new_file);
	
	$dlUpdate = new file_download($whmvers_arr['1'], $whm_new_file);
	exec("chmod 0755 ".$whm_new_file);
	unlink('/usr/local/cpanel/whostmgr/docroot/cgi/soholaunch/install_files/pro.tgz');
	exit;
} elseif($_GET['SohoWhmUpdate'] == 'finish'){
	echo $tabledisplay .= "<body style=\"background-color:#FFFFFF;\" onLoad=\"window.setTimeout('checkfinished()', 1500);\"> \n";	
	chdir('/usr/local/cpanel/whostmgr/docroot/cgi');
	exec("chmod 0755 ".$whm_new_file);
	exec("tar -xzvf ".$whm_new_file);
	chdir($changeTo);
	
	exit;
} else {	


	if($buildcomp != $currentStable || !file_exists($saveto) || $buildcompbeta != $betaStable || !file_exists($savetobeta)){
		$tabledisplay .= "<body style=\"background-color:#FFFFFF;\" onLoad=\"window.setTimeout('checkfinished()', 1500);\"> \n";
		$tabledisplay .= "<script language=\"javascript\"> \n";
		$tabledisplay .= " openInfoDialog(); \n";
		$tabledisplay .= "</script> \n";
	} else {
		$tabledisplay .= "<body style=\"background-color:#FFFFFF;\"> \n";	
	}
	exec("chmod 0755 ".$buildfile);
	exec("chmod 0755 ".$saveto);
	
	if(file_exists($whm_new_file)){
		exec("chmod -R 0755 /usr/local/cpanel/whostmgr/docroot/cgi/");
		exec("rm -f ".$whm_new_file);
	}
	if(!include("/usr/local/cpanel/whostmgr/docroot/cgi/soholaunch/functions/listinstalls.php")){
		echo "cannot include listinstalls.php!";
		exit;
	}
	
	$tabledisplay .= "        <div id=\"Body\"> \n";
	$tabledisplay .= "            <div id=\"Buttons\"></div> \n";
	$tabledisplay .= "            <div id=\"Header\"> \n";
	$tabledisplay .= "                <span class=\"Button\"> \n";
	$tabledisplay .= "                    <a href=\"/cgi/soholaunch/soholaunch.php\" title=\"Soholaunch Pro Edition\"><img src=\"images/soholaunch_logo.png\" alt=\"Soholaunch Pro Edition\"/></a><!--- <br/><a href=\"soholaunch.php\" title=\"Soholaunch Pro Edition\">Soholaunch Pro Edition</a> --> \n";
	$tabledisplay .= "                </span> \n";
	$tabledisplay .= "                <div class=\"Clear\"></div> \n";
	$tabledisplay .= "            </div> \n";
	$tabledisplay .= "            <div id=\"Container\"> \n";
	$tabledisplay .= "                <div style=\"width:800px;\" id=\"Left_Column\"> \n";
	$tabledisplay .= "                    <div style=\"width:800px;\" id=\"Navigation\"> \n";
	$tabledisplay .= "                        <ul> \n";
	$tabledisplay .= "                            <li><a href=\"javascript:showDis('intro')\" title=\"Main\" id=\"introBtn\" class=\"Blue\">Main</a></li> \n";
	$tabledisplay .= "                            <li><a href=\"javascript:showDis('settings')\" id=\"settingsBtn\" title=\"Settings\">Settings</a></li> \n";
	$tabledisplay .= "                            <li><a href=\"javascript:showDis('domains')\" id=\"domainsBtn\" title=\"Domains\">Domains</a></li> \n";
	$tabledisplay .= "                        </ul> \n";
	$tabledisplay .= "                    </div> \n";
	$tabledisplay .= "                </div> \n";
	$tabledisplay .= "                <div id=\"Right_Column\"> \n";
	$tabledisplay .= "                    <div id=\"Content\">               \n";
	$tabledisplay .= "                        <div id=\"Height\"></div> \n";
	$tabledisplay .= "    <form action=\"/cgi/soholaunch/soholaunch.php\"> \n";
	$tabledisplay .= "        <div class=\"Block\"> \n";
	$tabledisplay .= "        	<div id=\"intro\"> \n";
	$tabledisplay .= "            <h1>Soholaunch WHM Admin ".$whmconf_arr['0']."</h1> \n";
	$tabledisplay .= "            <p>Welcome to the Soholaunch WHM Admin panel!  Here you can view all your users domains, install / uninstall and define install settings.</p> \n";
	
	
	if($whmconf != $whmvers || !file_exists($whmfile)){
		$tabledisplay .= "            <p>An updated version of Soholaunch's WHM Pro Edition Installer is available.  <a href=\"soholaunch.php?SohoWhmUpdate=yes\">Click Here</a> to update!</p> \n";
	}
	
	$tabledisplay .= "         </div> \n";
	$tabledisplay .= "         <div id=\"domains\"> \n";
	$tabledisplay .= "         <h1>Soholaunch WHM Admin Installer</h1> \n";
	$tabledisplay .= "         <p id=\"domaintxt\"> \n";
	$tabledisplay .= "         	Below is a list of all user domains.  Click 'Install Pro' to install the latest version of Soholaunch on that domain and create a database. \n";
	$tabledisplay .= "         	If a domain already has Soholaunch installed you will see 'Uninstall' in the Action column, click 'Uninstall' to remove all Soholaunch \n";
	$tabledisplay .= "         	related files and databases.  You may also click 'Fix Permissions' to fix any incorrect permissions on the domain. \n";
	$tabledisplay .= "         </p> \n";
	
	if($DOMlist){
		$tabledisplay .= $DOMlist; //Domain list
	}else{
		//# Show Result Text
		$tabledisplay .= $Info;
	}
	
	$tabledisplay .= "        </div> \n";

	$tabledisplay .= "         <div id=\"settings\" style=\"padding:4px;\"> \n";
	$tabledisplay .= "         <h1>Soholaunch WHM Admin Settings</h1> \n";
	$tabledisplay .= "         <p id=\"domaintxt\"> \n";
	include('/usr/local/cpanel/whostmgr/docroot/cgi/soholaunch/settings.php');
	$tabledisplay .= "         </p> \n";
	$tabledisplay .= "         </div> \n";
	$tabledisplay .= "        </div> \n";
	$tabledisplay .= "    </form> \n";
	$tabledisplay .= "                        <div class=\"Clear\"></div> \n";
	$tabledisplay .= "                    </div> \n";
	$tabledisplay .= "                </div> \n";
	$tabledisplay .= "                <div class=\"Clear\"></div> \n";
	$tabledisplay .= "            </div> \n";
	$tabledisplay .= "        </div> \n";
	
	if(isset($_GET['installoption'])){
		$tabledisplay .= "<script language=\"javascript\">\n";
		$tabledisplay .= "showDis('settings')\n";
		$tabledisplay .= "</script>\n";
	}

	
	if(isset($_GET['domain']) || isset($_GET['uninstall']) || isset($_GET['fixPerms'])){
		$tabledisplay .= "<script language=\"javascript\">\n";
		$tabledisplay .= "showDis('domains')\n";
		$tabledisplay .= "$('domainsBtn').href='soholaunch.php?todomains=1'\n";
		$tabledisplay .= "$('domaintxt').style.display='none'\n";
		$tabledisplay .= "</script>\n";
	}
	if(isset($_GET['todomains'])){
		$tabledisplay .= "<script language=\"javascript\">\n";
		$tabledisplay .= "showDis('domains')\n";
		$tabledisplay .= "</script>\n";
	}
	   
	$tabledisplay .= "</body> \n";
	$tabledisplay .= "</html> \n";
	echo $tabledisplay;   
	   
	if($buildcomp != $currentStable || !file_exists($saveto)){
		unlink($buildfile);
		$file = fopen($buildfile, "w");
		fwrite($file, $currentStable);
		fclose($file);	
		unlink($saveto);
		$dlUpdate = new file_download($remotefile, $saveto);
	}
	
	if($buildcompbeta != $betaStable || !file_exists($savetobeta)){
		unlink($buildfilebeta);
		$file = fopen($buildfilebeta, "w");
		fwrite($file, $betaStable);
		fclose($file);	
		unlink($savetobeta);
		$dlUpdatebeta = new file_download($remotebetafile, $savetobeta);
	}
//	$betaStable =  $beta_build['build_name'];
//$remotebetafile =  $beta_build['download_full'];
	
}
?>