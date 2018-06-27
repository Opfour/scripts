<?php

/**
 * cPBackup - www.cpbackup.info
 * Created & Supported By Peter Kelly
 * Version: 1.8
 * ==============================================
 * Configuration Guide
 * For more information and help visit
 * https://www.cpbackup.info/wiki/How_To_Install
 * https://www.cpbackup.info/wiki/Configuration
 * https://www.cpbackup.info/configuration-encryption/
 * ==============================================
 * - License Key: Enter license key from https://www.cpbackup.info/billing/.
 *                If you have ordered a FREE license from the website above, entered it correctly in between the " "
 *                marks below and are still receiving errors. Please login to the website above, click services then
 *                your license and press RESET.
 */
$licensekey = "";

/**
 * Configuration Guide
 * - Reseller IP: Enter either your domain or the ip which your website is hosted on.
 * - Reseller Username: Enter your cPanel/WHM username.
 * - Reseller Password: Enter your cPanel/WHM password.
 * - Sleep: This is how long it should wait before each backup this is important so the server doesn't get overloaded.
 **NOTE* There is a minimum of 20 seconds between each backups. This is to ensure the backups do not bring down the hosting server **NOTE**
 * - Overall Notification: Receive the output from this backup script directly to your email.
 * - Output Debug: When this is set to 1. cPBackup will export the report displayed and emailed to the email set in overall_notification to debug/output.html every time the backup is run.
 * - Owned Exclusive: (1) Only backup accounts owned by "reseller_username", (0) Backup all accounts no matter who owns the account.
 */
$config["cpbackup"] = array(
    "reseller_ip" => "",
    "reseller_username" => "",
    "reseller_password" => "",
    "sleep" => "20",
    "overall_notification" => "",
    "output_debug" => "1",
	"owned_exclusive" => "0",
);

/**
 * Default Guide
 * - Backup Mode: (homedir | ftp | passiveftp | scp)
 *      homedir 	Stores the backup in the users home directory.
 *      ftp 		Transfers the backup to an offsite ftp server.
 *      passiveftp 	Transfers the backup to an offsite ftp server using Passive FTP mode.
 *      scp 		Transfers the backup to an offsite server using Secure Copy (SCP).
 *
 * The following are only required if the FTP mode is set to either ftp, passiveftp, scp or dropbox.
 * - Backup Host: FTP/SCP server hostname/ip.
 * - Backup User: FTP/SCP server username.
 * - Backup Password: FTP/SCP server password.
 * - Backup Port: FTP/SCP server port.
 * - Backup Dir: FTP/SCP server remote directory location. (%USER%, %DOMAIN%, %PACKAGE%, %DAILY%, %MONTHLY%, %ANNUALLY%)
 * - Per Account Email: The email address to receive the backup confirmation email sent from cPanel (This sends 1 for each account and contains information concerning FTP success/failure.
 */
$default = array(
	"backup_mode" => "",
	"backup_host" => "",
	"backup_user" => "",
	"backup_pass" => "",
	"backup_port" => "21",
	"backup_dir" => "/",
	"per_account_email" => "",
);

/**
*
* Dropbox Configuration
* - Enabled: Set to 1 to use Dropbox Uploader
* - FTP Root Dir: The FTP Folder to upload to DropBox.
* - FTP Delete File: Should the FTP files be deleted once they have been uploaded to DropBox?
* - Dropbox Dir: The folder to upload the files to on DropBox.
*
* For more information on configuring The Dropbox Uploader please visit
* http://www.cpbackup.info/dropbox-uploader/
*/
$config["dropbox"] = array(
	"enabled" => "0",
	"ftp_root_dir" => "/",
	"ftp_delete_files" => "1",
	"dropbox_dir" => "/",
	"output_debug" => "1",
);

/**
 * Custom Overrides
 * - This next section allows you to override the default settings as set above on a per account basis.
 * e.g $custom["username1"]["backup_dir"] = "/different/location1/";
 * or for multiple over-rides
 * e.g $custom["username1"]["backup_dir"] = "/different/location1/";
 *     $custom["username1"]["per_account_email"] = "user@email1.com";
 *     $custom["username2"]["backup_dir"] = "/different/location2/";
 */

/**
 * Exclude Accounts
 * - Don't want all your accounts backed up? Exclude certain accounts
 * $exclude_account["user"][] = "username";
 * $exclude_account["user"][] = "username2";
 * $exclude_account["user"][] = "username3";
 * $exclude_account["plan"][] = "package_name";
 * $exclude_account["domain"][] = "domain.com";
 * $exclude_account["ip"][] = "127.0.0.1";
 * $exclude_account["owner"][] = "username";
 */


/**
* Debug Configuration
* Having problems? Set $debug["info"] to 1 and re-run either run.php or run_dropbox.php.
* You will now have a lot more information to help resolve problems.
* If you are struggling please forward the report to admin@cpbackup.info.
*/
$debug["info"] = "0";

?>