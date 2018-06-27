<?php
##########################################################################################################################################
## Soholaunch(R) Site Management Tool
## Version 4.7
##
## Homepage:	 	http://www.soholaunch.com
## Bug Reports: 	http://bugz.soholaunch.com
## Community:     http://forum.soholaunch.com
##########################################################################################################################################

##########################################################################################################################################
## COPYRIGHT NOTICE                                                     
## Copyright 1999-2005 Soholaunch.com, Inc.  All Rights Reserved.       
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
##########################################################################################################################################

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*
    ______ _  __         ____                          __                   __
   / ____/(_)/ /___     / __ \ ____  _      __ ____   / /____   ____ _ ____/ /
  / /_   / // // _ \   / / / // __ \| | /| / // __ \ / // __ \ / __ `// __  / 
 / __/  / // //  __/  / /_/ // /_/ /| |/ |/ // / / // // /_/ // /_/ // /_/ /  
/_/    /_//_/ \___/  /_____/ \____/ |__/|__//_/ /_//_/ \____/ \__,_/ \__,_/  

> Accepts: "target host", "path to target script"
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
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
      	$this->msg = 'true';
         return $this->dlnow();
      }

   }
   
   
   /*----------------------------------------------------*/
   function dlnow() {
      //error_reporting(E_PARSE);
      
      // open remote file handle
      if ( !$fp1 = fopen($this->remote['path'],"r") ) {
         $this->msg = lang("Unable to open remote file.");
         return false;
      }
      
      // create local file
      if ( !$fp2 = fopen($this->local['path'],"w") ) {
         $this->msg = lang("Unable to write local copy of update file.");
         return false;
      }
      
      // read remote and write to local
      while (!feof($fp1)) {
           $output = fread($fp1,1024);
           fputs($fp2,$output);
      }
      
      fclose($fp1);
      fclose($fp2);
      
      $this->msg = lang("Remote update file downloaded successfully.");
      
      return true;
   }
   
   /*----------------------------------------------------*/
   
} // End remote file class


?>