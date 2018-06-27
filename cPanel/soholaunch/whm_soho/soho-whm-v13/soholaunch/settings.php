<?php
error_reporting(E_PARSE);
session_start();

//////////////////////////////////////////////////////////////////
///Create settings folder if it doesnt exist
//////////////////////////////////////////////////////////////////
$settings_dir = $changeTo."/settings";
if(!is_dir($settings_dir)){
	mkdir($settings_dir, 0755);
}


//////////////////////////////////////////////////////////////////
///Which build to install
//////////////////////////////////////////////////////////////////
$whichbuild = $settings_dir."/version_to_install.txt";

if(!file_exists($whichbuild)){
	$whichbuildfile = fopen($whichbuild, "w");
	fwrite($whichbuildfile, "Stable");
	fclose($whichbuildfile);
	$_SESSION['version_to_install'] = 'Stable';
}

if($_GET['installoption'] != ''){
	$whichbuildfile = fopen($whichbuild, "w");
	fwrite($whichbuildfile, $_GET['installoption']);
	fclose($whichbuildfile);
}
	$whichbuildfile = fopen($whichbuild, "r");
	$whichbuildread = fread($whichbuildfile, filesize($whichbuild));
	fclose($whichbuildfile);
	$_SESSION['version_to_install'] = $whichbuildread;



//////////////////////////////////////////////////////////////////
///Username Password install options
//////////////////////////////////////////////////////////////////
$password_option = $settings_dir."/password_option.txt";

if(!file_exists($password_option)){
	$password_optionfile = fopen($password_option, "w");
	fwrite($password_optionfile, "ask");
	fclose($password_optionfile);
	//$_SESSION['password_option'] = 'ask';
}

if($_GET['password_option'] != ''){
	$password_optionfile = fopen($password_option, "w");
	fwrite($password_optionfile, $_GET['password_option']);
	fclose($password_optionfile);
}
	$password_optionfile = fopen($password_option, "r");
	$password_optionread = fread($password_optionfile, filesize($password_option));
	fclose($password_optionfile);
	$_SESSION['password_option'] = $password_optionread;
	
	
//////////////////////////////////////////////////////////////////
///Default Username Password
//////////////////////////////////////////////////////////////////
$default_user_pass = $settings_dir."/default_user_pass.txt";

if(!file_exists($default_user_pass)){
	$default_user_passfile = fopen($default_user_pass, "w");
	fwrite($default_user_passfile, "admin\nadmin");
	fclose($default_user_passfile);
}

if($_GET['default_user'] != '' && $_GET['default_pass'] != ''){
	$default_user_passfile = fopen($default_user_pass, "w");
	$default_user_pass_data = $_GET['default_user']."\n".$_GET['default_pass'];
	fwrite($default_user_passfile, $default_user_pass_data);
	fclose($default_user_passfile);
}
	$default_user_passfile = fopen($default_user_pass, "r");
	$default_user_passread = fread($default_user_passfile, filesize($default_user_pass));
	fclose($default_user_passfile);
	$def_user_pass_ar = explode("\n", $default_user_passread);
	$_SESSION['default_user'] = $def_user_pass_ar['0'];
	$_SESSION['default_pass'] = $def_user_pass_ar['1'];

//echo $_SESSION['default_user']."<br/>".$_SESSION['default_pass']."<br/>";
	
//////////////////////////////////////////////////////////////////
//////build form
//////////////////////////////////////////////////////////////////
	$tabledisplay .= "<script language=\"javascript\">\n";
	$tabledisplay .= "function passopts(daoption){\n";
	$tabledisplay .= "	if(daoption == 'ask'){\n";
	$tabledisplay .= "		document.getElementById('default_user_pass').style.display='none';\n";
	$tabledisplay .= "		document.getElementById('def_user_name').disabled=true;\n";
	$tabledisplay .= "		document.getElementById('def_user_pass').disabled=true;\n";
	$tabledisplay .= "	}\n";
	$tabledisplay .= "	if(daoption == 'set'){\n";
	$tabledisplay .= "		document.getElementById('default_user_pass').style.display='block';\n";
	$tabledisplay .= "		document.getElementById('def_user_name').disabled=false;\n";
	$tabledisplay .= "		document.getElementById('def_user_pass').disabled=false;\n";
	$tabledisplay .= "	}\n";
	$tabledisplay .= "}\n";
	$tabledisplay .= "</script>\n";

	$tabledisplay .= "         	<form name=installtype id=installtype method=GET action=\"/cgi/soholaunch/soholaunch.php\">\n";
	$tabledisplay .= "<div style=\"width:80%; border:1px solid #003C49;\"><p>\n";
	$tabledisplay .= "         	<span style=\"font-weight:bold;\">When installing soholaunch, would you like to install the latest stable build or the latest beta build?</span><br/>\n";
	$tabledisplay .= "         	<input type=radio name=installoption value=Stable";
	if($_SESSION['version_to_install'] == 'Stable'){ $tabledisplay .= " checked"; }
	$tabledisplay .= "> Latest Stable (".$currentStable.")<br/>\n";
	$tabledisplay .= "         	<input type=radio name=installoption value=Latest";
	if($_SESSION['version_to_install'] == 'Latest'){ $tabledisplay .= " checked"; }
	$tabledisplay .= "> Latest Beta (".$betaStable.")<br/><br/>\n";
	$tabledisplay .= "</p></div><br/>\n";
	$tabledisplay .= "<div style=\"width:80%; border:1px solid #003C49;\"><p>\n";
	$tabledisplay .= "         <span style=\"font-weight:bold;\">New Soholaunch installation username & password options</span><br/> \n";
	$tabledisplay .= "         <input type=\"radio\" onClick=\"passopts('ask');\" name=\"password_option\" value=\"ask\"";
	if($_SESSION['password_option'] == 'ask'){ $tabledisplay .= " checked"; }
	$tabledisplay .= "> Prompt for username and password when installing. <br/>\n";
	$tabledisplay .= "         <input onClick=\"passopts('set');\" type=\"radio\" name=\"password_option\" value=\"set\"";
	if($_SESSION['password_option'] == 'set'){ $tabledisplay .= " checked"; }
	$tabledisplay .= "> Use preset username and password for all new installations. <br/>\n";
	
	
	$tabledisplay .= "<div id=\"default_user_pass\" style=\"padding:3px; display:";
	if($_SESSION['password_option'] == 'set'){ 
		$tabledisplay .= " block;\">\n";
	} else {
		$tabledisplay .= " none;\">\n";
	}
	
	
	$tabledisplay .= "<p>Default Username:&nbsp;<input id=\"def_user_name\" type=\"text\" name=\"default_user\" value=\"".$_SESSION['default_user']."\"><br/></p>";
	$tabledisplay .= "<p>Default Password:&nbsp;&nbsp;<input id=\"def_user_pass\" type=\"text\" name=\"default_pass\" value=\"".$_SESSION['default_pass']."\"><br/></p>";
	
	
	$tabledisplay .= "</div>\n";
	$tabledisplay .= "</p><br/></div>\n";
	$tabledisplay .= "         <br/><br/><input type=submit value=\"Save Settings\"> \n";
	$tabledisplay .= "         </form> \n";
	
?>