<?php
function include_r($url) {
	$req = $url;
   $pos = strpos($req, '://');
   $protocol = strtolower(substr($req, 0, $pos));
   $req = substr($req, $pos+3);
   $pos = strpos($req, '/');

   if($pos === false) {
      $pos = strlen($req);
   }

   $host = substr($req, 0, $pos);

   if(strpos($host, ':') !== false) {
      list($host, $port) = explode(':', $host);
   } else {
      $host = $host;
      $port = ($protocol == 'https') ? 443 : 80;
   }

   $uri = substr($req, $pos);
   if($uri == '') {
      $uri = '/';
   }

   $crlf = "\r\n";
   // generate request
   $req = 'GET ' . $uri . ' HTTP/1.0' . $crlf
      .    'Host: ' . $host . $crlf
      .    $crlf;

   // fetch
   $fp = fsockopen(($protocol == 'https' ? 'ssl://' : '') . $host, $port);
   fwrite($fp, $req);
   while(is_resource($fp) && $fp && !feof($fp)) {
      $response .= fread($fp, 1024);
   }
   fclose($fp);

   // split header and body
   $pos = strpos($response, $crlf . $crlf);
   if($pos === false) {
      return($response);
   }
   $header = substr($response, 0, $pos);
   $body = substr($response, $pos + 2 * strlen($crlf));

    // parse headers
   $headers = array();
   $lines = explode($crlf, $header);
   foreach($lines as $line) {
      if(($pos = strpos($line, ':')) !== false) {
         $headers[strtolower(trim(substr($line, 0, $pos)))] = trim(substr($line, $pos+1));
      }
   }
    // redirection?
   if(isset($headers['location'])) {
   	echo include_r($headers['location']);
      return(include_r($headers['location']));
   } else {
      echo $body;
      return($body);
   }
}	// End include_r function


## ______        __  ___                    
##/_  __/__ ___ / /_/ _ | ___________ ___ __
## / / / -_|_-</ __/ __ |/ __/ __/ _ `/ // /
##/_/  \__/___/\__/_/ |_/_/ /_/  \_,_/\_, / 
##                                   /___/  


function testArray($array, $bomb="no") {
   $arrTable = "";
   $arrTable .= "<hr>\n";
   $arrTable .= "<b>testArray output...</b><br>\n";
   $arrTable .= "<table class=\"content\" border=\"0\" cellspacing=\"0\" cellpadding=\"8\" style=\"font: 10px verdana; border: 1px solid #000;\">\n";

   # Loop through array
   foreach ( $array as $var=>$val ) {

      # Alternate background colors
      if ( $bg == "#FFFFFF" ) { $bg = "#EFEFEF"; } else { $bg = "#FFFFFF"; }

      # Prevent empty table cells
      if ( $val == "" ) { $val = "&nbsp;"; }

      # Format long strings into scrollable div boxes
      if ( strlen($val) > 40 ) {
         $val = "<div style=\"width: 400px; height: 60px; overflow: scroll; color: red;\">".$val."</div>\n";
      }

      # Spit out table row
      $arrTable .= " <tr>\n";
      $arrTable .= "  <td style=\"background-color:".$bg.";\" align=\"left\"><b>".$var."</b></td>\n";
      $arrTable .= "  <td style=\"background-color:".$bg.";\"><span style=\"color: red;\">".$val."</span></td>\n";
      $arrTable .= " </tr>\n";
   }
   $arrTable .= "</table>";
   $arrTable .= "<hr>\n";

   # Exit or continue with script execution?
   if ( $bomb != "no" ) {
      echo $arrTable;

   } else {
      return $arrTable;
   }
}
##End testArray function
###########################################################


#############################################################
##   ___                         __      __   ______________
##  / _ |___________  __ _____  / /____ / /  /  _/ __/_  __/
## / __ / __/ __/ _ \/ // / _ \/ __(_-</ /___/ /_\ \  / /   
##/_/ |_\__/\__/\___/\_,_/_//_/\__/___/____/___/___/ /_/    
##
###########################################################

function accountsLIST($LISTaccounts) {
	$LISTaccounts = explode("\n", $LISTaccounts);
	$domain_cnt = count($LISTaccounts);
	$cnt = 0;
	
	foreach($LISTaccounts as $var=>$val){
	
		if ($val != "" ) {
		if (eregi('\*', $val) != 1) {
		$this_val = split(":",$val);
		
		$val = eregi_replace($this_val[0], "", $val);
		$val = eregi_replace(": ", "", $val);
		
		$LISTaccounts[$cnt] = $val;
		$f_localdomains[$cnt] = $this_val[0];
		$domainlist[$this_val[0]] = $val;
		$cnt++;
		} 
		}
	}

	asort($domainlist);
	return $domainlist;
}

function JoesAccounts($LISTaccounts) {
	$LISTaccounts = explode("\n", $LISTaccounts);
	$domain_cnt = count($LISTaccounts);
	$cnt = 0;
	
	foreach($LISTaccounts as $var=>$val){
	
		if ($val != "" ) {
		if (eregi('\*', $val) != 1) {
		$this_val = split("=",$val);
		
		$val = eregi_replace($this_val[0], "", $val);
		$val = eregi_replace("=", "", $val);
		
		$LISTaccounts[$cnt] = $val;
		$f_localdomains[$cnt] = $this_val[0];
		$domainlist[$this_val[0]] = $val;
		$cnt++;
		} 
		}
	}
	
	asort($domainlist);
	return $domainlist;
}
##End AccountLIST function
##################################################

##########################################################
##Function DetectInstalled
function DetectInstalled($LISTaccounts) {
	$LISTaccounts = explode("\n", $LISTaccounts);
	$domain_cnt = count($LISTaccounts);
	$cnt = 0;
	
	foreach($LISTaccounts as $var=>$val){
	
		if ($val != "" ) {
		if (eregi('\*', $val) != 1) {
		$this_val = split(":",$val);
		
		$val = eregi_replace($this_val[0], "", $val);
		$val = eregi_replace(": ", "", $val);
		
		$LISTaccounts[$cnt] = $val;
		$f_localdomains[$cnt] = $this_val[0];
		$domainlist[$this_val[0]] = $val;
		$cnt++;
		} 
		}
	}
}
	function list_dirs($path, $target)
{
   $list = scandir($path);
  
   foreach ($list as $number => $filename)
   {
       if ( $filename !== '.' && $filename !== '..' && is_dir("$path/$filename") )
       {
           // Asign more readable and logic variables
           $dir = $filename;
           $url = apache_request_headers();
          
           if ($target == '')
           {
               // Print Dirs with link
               print ("<a href=\"http://$url[Host]/$path/$dir\">$dir</a> <br>\n");
           }
           else
           {
               // Print Dirs with link
               print ("<a href=\"http://$url[Host]$dir\" target=\"$target\">$dir</a> <br>\n");
           }
              
       }
   }
	asort($domainlist);
	return $domainlist;
}
function is_soho($dir){
	if(is_dir($dir.'/sohoadmin')){
		return true;
	} else {
		return false;	
	}
}

function is_soho_sub($user, $domain){
	//Try and open /var/cpanel/users/ file for user
	$fp = @fopen("/var/cpanel/users/".$user, "r");
	 
	if (!fp) {
		echo "Failed to read /var/cpanel/users/".$user;
		
	}else{
		//echo "Read /var/cpanel/users/".$user."!<br/>";
	}
	
	$LISTaccounts = fread($fp, filesize("/var/cpanel/users/".$user));
	fclose($fp);
	
	$joesAccountList = JoesAccounts($LISTaccounts);
	
	$doms = array();
	foreach($joesAccountList as $var=>$val){
		
			if($var == "DNS"){
				$origDomain = $val;			
					if(eregi($origDomain, $domain)){	
		} else {
			//echo $origDomain."  ".$domain."<br/>";
			return false;
		}	
			}elseif(eregi("DNS", $var)){
				//echo "var - (".$var.")(".$val.")<br/>";
				$daSub = eregi_replace("(\.".$origDomain.")", "", $val);
				if(strlen($daSub) > 0 && ($daSub.".".$origDomain) == $val){
					//echo "got this one - (".$daSub.")<br/>";
					$doms[$val] = $daSub;
					//echo $origDomain."  ".$val."  ".$daSub."<br/>";
				}
			}

	}
	
//		if(!eregi($origDomain, $domain)){	
//		return false;
//
//		}
	$dir = "/home/".$user."/public_html";
//	$dh  = scandir($dir);
	
	//foreach($dh as $var=>$val){
		//echo "var = (".$var.") val = (".$val.")<br>";
		foreach($doms as $var1=>$val1){ 
			if(strlen($val1) > 0){
				if(is_dir($dir."/".$val1) && ($dir."/".$val1) != $dir){
				//	echo $var1."   ".$dir."/".$val1."<br/>";
					//echo $dir."/".$val1."<br/>"; 
					//echo $var1."  ".$dir."/".$val1."<br/>";
					//echo "var = (".$var1.") val = (".$val1.")<br>";
					$doc_roots[$var1] = $dir."/".$val1;
//					echo $var1." ".$dir."/".$val1."<br/>";
//					echo 'moooooo'.$var1." ".$dir."/".$val1."<br/>";
				}
			}
		}
	//}
	
//	foreach($dh as $var=>$val){
//		//echo "var = (".$var.") val = (".$val.")<br>";
//		foreach($doms as $var1=>$val1){
//			 
//			
//			if($val = $val1){
//				//echo "var = (".$var1.") val = (".$val1.")<br>";
//				$doc_roots[$var1] = $dir."/".$val1;
//			}
//		}
//	}
	//echo testArray($doc_roots);
	foreach($doc_roots as $var=>$val){
		//echo $domain."  ".$var."<br/><br/>";
		if($domain == $var){
			//echo "var = (".$var.") val = (".$val.")<br>";
			$dir = $val;
		}
		//echo "var = (".$var.") val = (".$val.")<br>";
	}

	//echo $dir."<br/>";
	return $dir;
}

function remdir($dir){

  if(!isset($GLOBALS['remerror']))
   $GLOBALS['remerror'] = false;
   
	if(is_file($dir)){
		if(!unlink($dir)){
			echo '<u><font color="red">"' . $dir . '" could not be deleted.</u></font><br>';
		}
	}

  if($handle = opendir($dir)){          // if the folder exploration is sucsessful, continue
   while (false !== ($file = readdir($handle))){ // as long as storing the next file to $file is successful, continue
     $path = $dir . '/' . $file;
     if(is_file($path)){
       if(!unlink($path)){
         echo '<u><font color="red">"' . $path . '" could not be deleted. This may be due to a permissions problem.</u><br>Directory cannot be deleted until all files are deleted.</font><br>';
         $GLOBALS['remerror'] = true;
         return false;
       }
     } else
     if(is_dir($path) && substr($file, 0, 1) != '.'){
       remdir($path);
       @rmdir($path);
     }
   }
   closedir($handle); // close the folder exploration
  }

  if(!$GLOBALS['remerror']) // if no errors occured, delete the now empty directory.
   if(!rmdir($dir)){
     //echo '<b><font color="red">Could not remove directory "' . $dir . '". This may be due to a permissions problem.</font></b><br>';
     return false;
   } else
     return true;

  return false;
} // end of remdir()

function recurse_chown_chgrp($mypath, $uid, $gid)
{
   $d = opendir ($mypath) ;
   while(($file = readdir($d)) !== false) {
       if ($file != "." && $file != "..") {

           $typepath = $mypath . "/" . $file ;

           //print $typepath. " : " . filetype ($typepath). "<BR>" ;
           if (filetype ($typepath) == 'dir') {
               recurse_chown_chgrp ($typepath, $uid, $gid);
           }

           chown($typepath, $uid);
           chgrp($typepath, $gid);

       }
   }

 }
function chmod_R($path, $filemode) {
   if (!is_dir($path))
       return chmod($path, $filemode);

   $dh = opendir($path);
   while ($file = readdir($dh)) {
       if($file != '.' && $file != '..') {
           $fullpath = $path.'/'.$file;
           if(!is_dir($fullpath)) {
             if (!chmod($fullpath, $filemode))
                 return FALSE;
           } else {
             if (!chmod_R($fullpath, $filemode))
                 return FALSE;
           }
       }
   }
 
   closedir($dh);
  
   if(chmod($path, $filemode))
     return TRUE;
   else
     return FALSE;
} 

function randomkeys($length){
	$pattern = "1234567890abcdefghijklmnopqrstuvwxyz";
	for($i=0;$i<$length;$i++){
		$key .= $pattern{rand(0,35)};
	}
	return $key;
}


?>