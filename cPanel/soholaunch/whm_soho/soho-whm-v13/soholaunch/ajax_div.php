<?php
error_reporting(E_PARSE);
session_start();

$Info = "<div id=\"rux1\" style=\"position: ";
if(eregi('IE', $_SERVER['HTTP_USER_AGENT'])) { $Info .= "fixed; top: 0%; left: 0%;"; } else { $Info .= "fixed; top: 0%; left: 0%;"; }
$Info .= " width:100%; height:100%;\">\n";
		
//echo "<div id=\"rux2\" style=\"position: ";
//if(eregi('MSIE', $_SERVER['HTTP_USER_AGENT'])) { echo "absolute; top: 45%; left: 20%; z-index:3;"; } else { echo "absolute; top: 40%; left: 20%;"; }
//echo " width:600px; background-color:#ffffff;  border:1px inset #000000;\">&nbsp;</div>\n";
//	
$Info .= "<div id=\"rux3\" style=\"background-color: #99ABAF;  position:absolute; ";
if(eregi('MSIE', $_SERVER['HTTP_USER_AGENT'])) { $Info .= " top: 45%; left: 20%; z-index:4;"; } else { $Info .= " top:40%; left: 20%;"; }
$Info .= "width:600px; border:1px solid #003C49;\">\n";


$Info .= "<table cellpadding=\"0\" cellspacing=\"0\" width=\"600px\"  style=\"vertical-align:top; color: #000000;>\n";
$Info .= "<tr><td style=\"height:30px; cursor:pointer;\" align=right><a onmouseover=\"style.cursor='pointer'\" style=\"color: #ffffff; text-decoration: none; border-bottom:1px solid #000000; border-top:1px solid #000000; border-left:1px solid #000000; border-right:1px solid #000000; background-color: red;\" onclick=\"Dialog.closeInfo();\">&nbsp;X&nbsp;</a>&nbsp;<font color=#ffffff>CLOSE</font>\n";
$Info .= "</td></tr>\n";
$Info .= "<tr><td style=\"font-size:14px; vertical-align:top; padding:7px; color:black;\">\n";

$cpaneluser = $_GET['cpanel_user'];
$cpanel_domain = $_GET['cpanel_domain'];
include('functions/shared_functions.php');

$filename = $_GET['doc_root']."/sohoadmin/config/isp.conf.php";		// This server should be setup; if not; let's set it up.
//$filename = "/home/".$cpaneluser."/public_html/sohoadmin/config/isp.conf.php";		// This server should be setup; if not; let's set it up.

if (!$file = fopen("$filename", "r")) {
	$Info .= 'cant open ispconf';
} else {
	$body = fread($file,filesize($filename));
	$lines = split("\n", $body);
	$numLines = count($lines);
	for ($x=2;$x<=$numLines;$x++) {
		if (!eregi("#", $lines[$x])) {
			$variable = strtok($lines[$x], "="); 
			$value = strtok("\n");
			$value = rtrim($value);
			${$variable} = $value;

		}
	}
	fclose($file);
}

$db_server = 'localhost';

$link = mysql_connect("$db_server", "$db_un","$db_pw");
$sel = mysql_select_db("$db_name");
$result = mysql_list_tables("$db_name");

$query = 'SELECT * FROM login';

if(!$result = mysql_query($query)) {
	//echo '-OUTPUT-'.$dflogin_user.'::'.$dflogin_pass.'-OUTPUT-';
	$sohousername = $dflogin_user;
	$sohopassword = $dflogin_pass;
} else {
	$blue = mysql_fetch_array($result);
	$sohousername = $blue['Username'];
	$sohopassword = $blue['Password'];
}


//$Info = "<font color=\"#ffc417\">Soholaunch Pro Edition</font> ";
$Info .= "<h3><font color=\"#ffffff\">Soholaunch Information for http://".$cpanel_domain."</font></h3>";

$Info .= "<table cellpadding=\"0\" cellspacing=\"0\" style=\"background-color: #ffffff; vertical-align:top; color: #000000; border:1px solid #003C49;\">\n";
$Info .= "<tr><td style=\"font-family:Trebuchet MS,Verdana,sans-serif; font-weight:normal; padding: 4px; font-size:14px; vertical-align:top;\">\n";

$Info .= "<font color=\"#000000\"><strong>URL: </strong><a href=\"http://".$cpanel_domain."/sohoadmin/index.php\" style=\"color:#003C49; text-decoration:none;\" target=\"_BLANK\">http://".$cpanel_domain."/sohoadmin/index.php</a>\n<br>";

$d_ar = explode('/', $doc_root);		



if(count($d_ar) > 4){
  $Info .= "<strong><font color=\"#000000\">Temp URL: </strong><a style=\"text-decoration:none;\" href=\"http://".$_SERVER['HTTP_HOST']."/~".$cpaneluser."/".$d_ar['4']."/sohoadmin/index.php\" style=\"color:#003C49; text-decoration:none;\" target=\"_BLANK\">http://".$_SERVER['HTTP_HOST']."/~".$cpaneluser."/".$d_ar['4']."/sohoadmin/index.php</a></strong>\n<br>";
} else {
  $Info .= "<strong><font color=\"#000000\">Temp URL: </strong><a style=\"text-decoration:none;\" href=\"http://".$_SERVER['HTTP_HOST']."/~".$cpaneluser."/sohoadmin/index.php\" style=\"color:#003C49; text-decoration:none;\" target=\"_BLANK\">http://".$_SERVER['HTTP_HOST']."/~".$cpaneluser."/sohoadmin/index.php</a></strong>\n<br>";
}

//$Info .= "<font color=\"#000000\"><strong>Temp URL:</strong> <a href=\"http://".$_SERVER['HTTP_HOST']."/~".$cpaneluser."/sohoadmin/index.php\" style=\"color:#003C49; text-decoration:none;\" target=\"_BLANK\">http://".$_SERVER['HTTP_HOST']."/~".$cpaneluser."/sohoadmin/index.php</a>\n<br>";



$Info .= "<font color=\"#000000\"><strong>Sohoadmin Username: </font></strong><font color=\"#003C49\">".$sohousername."\n</font><br>";
$Info .= "<font color=\"#000000\"><strong>Sohoadmin Password: </strong></font><font color=\"#003C49\">".$sohopassword."\n</font><br>";
$Info .= "</td></tr></table>\n";


$Info .= "<br/><br/></td></tr></table>\n";
$Info .= "</div></div>\n";
echo $Info;
?>