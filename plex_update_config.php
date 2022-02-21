<?php

//USER VARIABELS
$use_sessions=1;
$plex_skip_versions_location="/volume1/server-plex/web/config/plex_versions";
$config_file_location="/volume1/server-plex/web/config/config_files/config_files_local/plex_logging_variables.txt";
$plex_update_shell_file_log_location="/volume1/server-plex/web/logging/notifications/plex_update.txt";
$form_submit_location="index.php?page=6&config_page=plex_update";


if($use_sessions==1){
	if($_SERVER['HTTPS']!="on") {

	$redirect= "https://".$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];

	header("Location:$redirect"); } 

	// Initialize the session
	if(session_status() !== PHP_SESSION_ACTIVE) session_start();
	 
	// Check if the user is logged in, if not then redirect him to login page
	if(!isset($_SESSION["loggedin"]) || $_SESSION["loggedin"] !== true){
		header("location: login.php");
		exit;
	}
}
include $_SERVER['DOCUMENT_ROOT']."/functions.php";
error_reporting(E_ALL ^ E_NOTICE);

$server2_email_error="";
$server2_email_interval_error="";
$plex_skip_version_error="";
$generic_error="";
$delete_file="";
$file_delete_error="";
		
if(isset($_POST['delete_files_submit'])){
	[$delete_file, $file_delete_error] = test_input_processing($_POST['remove_plex_version'], "", "file", 0, 0);
	if($generic_error=="" AND $delete_file!=""){
		if(file_exists("".$plex_skip_versions_location."/".$delete_file."")){
			unlink("".$plex_skip_versions_location."/".$delete_file."");
		}else{
			$file_delete_error="<font size=\"1\"><font color=\"red\">The selected file does not exist</font></font>";
		}
	}
}

if(isset($_POST['submit_PLEX_config'])){
	if (file_exists("$config_file_location")) {
		$data = file_get_contents("$config_file_location");
		$pieces = explode(",", $data);
	}
		   
	[$server2_email, $server2_email_error] = test_input_processing($_POST['server2_email'], $pieces[2], "email", 0, 0);
		  
	[$plex_pass_beta, $generic_error] = test_input_processing($_POST['plex_pass_beta'], "", "checkbox", 0, 0);
		  
	[$minimum_package_age, $generic_error] = test_input_processing($_POST['minimum_package_age'], $pieces[1], "numeric", 1, 14);
		  
	[$fix_bad_intel_driver, $generic_error] = test_input_processing($_POST['fix_bad_intel_driver'], "", "checkbox", 0, 0);
		  
	[$script_enable, $generic_error] = test_input_processing($_POST['script_enable'], "", "checkbox", 0, 0);
		 	  
	$put_contents_string="".$plex_pass_beta.",".$minimum_package_age.",".$server2_email.",".$fix_bad_intel_driver.",".$script_enable."";
		  
	file_put_contents("$config_file_location",$put_contents_string );
		  
		  
	if (file_exists("$plex_update_shell_file_log_location")) {
		$data = file_get_contents("$plex_update_shell_file_log_location");
		[$plex_skip_version, $generic_error] = test_input_processing($_POST['plex_skip_version'], "", "filter", 0, 0);
			  
		$plex_skip_version=RemoveSpecialChar_directory($plex_skip_version);
				  
		if($plex_skip_version!=""){
			if (strpos($data, $plex_skip_version) !== false) {
				if (file_exists("$plex_skip_versions_location/".$plex_skip_version.".skip")==FALSE) {
					file_put_contents("$plex_skip_versions_location/".$plex_skip_version.".skip",$plex_skip_version );
				}else{
					$plex_skip_version_error="<font color=\"red\" size=\"1\">PLEX Version already set to be skipped</font>";
				}
			}else{
				$plex_skip_version_error="<font color=\"red\" size=\"1\">PLEX Version Not Previously Reported By Script</font>";
			}
		}
	}
		  
}else{
	if (file_exists("$config_file_location")) {
		$data = file_get_contents("$config_file_location");
		$pieces = explode(",", $data);
		$plex_pass_beta=$pieces[0];
		$minimum_package_age=$pieces[1];
		$server2_email=$pieces[2];
		$fix_bad_intel_driver=$pieces[3];
		$script_enable=$pieces[4];
	}else{
		$plex_pass_beta=0;
		$minimum_package_age=7;
		$server2_email="admin@admin.com";
		$fix_bad_intel_driver=0;
		$script_enable=0;
		$put_contents_string="".$plex_pass_beta.",".$minimum_package_age.",".$server2_email.",".$fix_bad_intel_driver.",".$script_enable."";
			  
		file_put_contents("$config_file_location",$put_contents_string );
	}
}
	   
	   
print "
	<br>
	<fieldset>
		<legend>
			<h3>PLEX Auto Updater Configuration Settings</h3>
		</legend>
		<table border=\"0\">
			<tr>
				<td>";
					if ($script_enable==1){
						print "<font color=\"green\"><h3>Script Status: Active</h3></font>";
					}else{
						print "<font color=\"red\"><h3>Script Status: Inactive</h3></font>";
					}
print "			</td>
			</tr>
			<tr>
				<td align=\"left\">
					<form action=\"".$form_submit_location."\" method=\"post\">
						<p><input type=\"checkbox\" name=\"script_enable\" value=\"1\" ";
						if ($script_enable==1){
							print "checked";
						}
						print "> Enable Script?</p>
						<p>Alert Email Recipient: <input type=\"text\" name=\"server2_email\" value=".$server2_email."> ".$server2_email_error."</p>
						<p>Minimum Package Age: <select name=\"minimum_package_age\">";
							if ($minimum_package_age==1){
								print "<option value=\"1\" selected>1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==2){
								print "<option value=\"1\">1</option>
								<option value=\"2\" selected>2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==3){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\" selected>3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==4){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\" selected>4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==5){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\" selected>5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==6){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\" selected>6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==7){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\" selected>7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==8){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\" selected>8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==9){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\" selected>9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==10){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\" selected>10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==11){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\" selected>11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==12){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\" selected>12</option>
								<option value=\"13\">13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==13){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\" selected>13</option>
								<option value=\"14\">14</option>";
							}else if ($minimum_package_age==14){
								print "<option value=\"1\">1</option>
								<option value=\"2\">2</option>
								<option value=\"3\">3</option>
								<option value=\"4\">4</option>
								<option value=\"5\">5</option>
								<option value=\"6\">6</option>
								<option value=\"7\">7</option>
								<option value=\"8\">8</option>
								<option value=\"9\">9</option>
								<option value=\"10\">10</option>
								<option value=\"11\">11</option>
								<option value=\"12\">12</option>
								<option value=\"13\">13</option>
								<option value=\"14\" selected>14</option>";
							}
						print "</select></p>
						<p><input type=\"checkbox\" name=\"plex_pass_beta\" value=\"1\" ";
						if ($plex_pass_beta==1){
							print "checked";
						}
						print "> Download PLEX-PASS Beta Packages?</p>
						<p><input type=\"checkbox\" name=\"fix_bad_intel_driver\" value=\"1\" ";
						if ($fix_bad_intel_driver==1){
							print "checked";
						}
						print "> Delete Bad Intel Driver? (Needed for Gemini Lake Processors)</p>
						<p>Add PLEX Version to skip?: <input type=\"text\" name=\"plex_skip_version\" value=\"\"> ".$plex_skip_version_error."</p>
						<center><input type=\"submit\" name=\"submit_PLEX_config\" value=\"Submit\" /></center>
					</form>";
		
		
		
					/***************************************
					has the user chosen to list any already downloaded files?
					/**************************************/
					print "
					<br><p>Skipped PLEX Versions</p>";
					$dir    = $plex_skip_versions_location;
					$files1 = scandir($dir);
					$counter=1;
					// Loop through array
					foreach($files1 as $value){
						if ($value!="."){
							if ($value!=".."){
								print "<form action=\"".$form_submit_location."\" method=\"post\">";
								print "<p>".$counter.".) <font size=\"2\">".$value."</font></a>";
								print "  |  <input type=\"submit\" name=\"delete_files_submit\" value=\"Remove Skipped Version\" /> ".$file_delete_error."";
								print "<input type=\"hidden\" name=\"remove_plex_version\" value=\"".$value."\" />";
								print "</p></form>";
								$counter++;
							}
						}
					}
		
		
print "
				</td>
			</tr>
		</table>
	</fieldset>";
?>
