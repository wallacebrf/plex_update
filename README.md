<div id="top"></div>
<!--
*** comments....
-->



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/wallacebrf/plex_update">
  </a>

<h3 align="center">Synology DSM6/7 PLEX Native Package Auto Update Script and PHP Configuration Page</h3>

  <p align="center">
    This project allows for the automatic updates to PLEX installed on Synology NAS devices running DSM6 or DSM7. The script will first terminate any active streams and send the affected users a custom message. The script will stop the PLEX package within DSM, download the latest release, install th update, and restart PLEX. 
    <br />
    <a href="https://github.com/wallacebrf/plex_update"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/wallacebrf/plex_update/issues">Report Bug</a>
    ·
    <a href="https://github.com/wallacebrf/plex_update/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#About The Project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
### About The Project

Auto-Update Plex

This script is for synology systems running DSM6 or DSM7 for automatically updating the native install package from the PLEX website. 

The script polls the PLEX download page. If a new update is available, an email will be sent to the configured email address detailing the updating including the new and fixed release notes. If the package was released longer than a configurable number of days (1-14 days) the update will be installed otherwise the update will be skipped. 

If it is desired to not install a particular release, that version can be defined as "skipped" and the script will ignore that release going forward. 

The script will first terminate any active streams and send the affected users a custom message (configuration detailed below). The script will stop the PLEX package within DSM, download the latest release, install the update, and restart PLEX. It will then save the downloaded PLEX installer to a configured location for archiving. When the script is complete, an email containing the logs of the update will be sent to the configured email address. 

The script has a configuration page that allows the user to set the following parameters:

1.) enable or disable the script

2.) email address to send logs / notices to

3.) minimum age of the latest PLEX package release before the upgrade will occur. this is adjustable between 1 and 14 days. this is used to allow a user to wait and see if issues arise with a particular PLEX release before installing

4.) Download PLEX-PASS Beta Packages allows to control if the regular public release or the beta release updates are used

5.) Delete Bad Intel Driver? (Needed for Gemini Lake Processors) allows to delete the intel driver to fix issues with the DS920. this issue appears to be fixed and is not needed at the moment, but the ability to perform this function is still there

6.) add a version of PLEX to SKIP so the installer will ignore the release. this is useful if the release appears to have a bug the user is concerned about

the skipped versions can also be removed if the version is actually desired

<img src="https://raw.githubusercontent.com/wallacebrf/plex_update/main/plex_update_config1.png" alt="config">

<p align="right">(<a href="#top">back to top</a>)</p>



### Built With

* [BASH .sh](https://www.gnu.org/software/bash/)
* [PHP](https://www.php.net/)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This project requires the a Synology NAS running DSM6 or DSM7. This project only supports the native PLEX package supplied by PLEX at the following site: https://www.plex.tv/media-server-downloads/. This project is not intended to update Docker installations and does not support other operating systems. 

### Prerequisites

Synology NAS running DSM6 or DSM7

Native PLEX package from https://www.plex.tv/media-server-downloads/ 

Use of Synology Task Scheduler

Synology MailPlus Server installed and configured to relay email messages to hotmail, gmail etc. If MailPlus server is not available, use task scheduler's integrated email function if desired. 

Synology web station must be configured with PHP available 

### Installation

### .sh script file `PlexUpdate.sh`

the .sh script file has the following user configurable parameters

`lock_file_location="/volume1/web/logging/notifications/PlexUpdate.lock"`

`config_file_location="/volume1/web/config/config_files/config_files_local/plex_logging_variables.txt"`

`PMS_IP='192.168.1.200'`

`plex_installed_volume="volume1"`

`plex_installer_location="/volume1/Server2/Software/Software/PLEX"`

`log_file_location="/volume1/web/logging/notifications/plex_update.txt"`

`MSG='PLEX_Update_Installation_In_Progress'`

`plex_skip_versions_directory="/volume1/web/config/plex_versions"`

`from_email_address="admin@admin.com"`


1. "lock_file_location" is used to create a temporary directory while the script is executing to prevent more than once script instance from running. configure this parameter for where on the synology NAS the temp folder will be placed
2. "config_file_location" is where the script reads the parameters controlled by the PHP web page. configure this for the desired location. make sure this value is also entered into the PHP file
3. "PMS_IP" is the IP of the target PLEX server
4. "plex_installed_volume" is for the volume PLEX is currently installed on, this is typically volume1
5. "plex_installer_location" is where the PLEX installation packages that are downloaded will be saved
6. "log_file_location" is where the log file generated by the script will be saved. make sure this value is also entered into the PHP file
7. "MSG" is the message that will be displayed to users with any active plex streams when they are terminated before stopping plex. ensure there are no spaces
8. "plex_skip_versions_directory" is a directory where the PHP web page and the script keep track of what versions of PLEX have been set to be skipped. make sure this value is also entered into the PHP file
9. "from_email_address" is the email address the notifications will be reported as origonating from.

### -> PHP Webserver

1. copy `plex_update_config.php` and `functions.php` onto a locally hosted web server the .sh script file is also installed on. Ensure `functions.php` is in the root of the web server public directory
2. within the `plex_update_config.php` file edit the following lines as desired

`$use_sessions=1;`

`$plex_skip_versions_location="/volume1/server-plex/web/config/plex_versions";`

`$config_file_location="/volume1/server-plex/web/config/config_files/config_files_local/plex_logging_variables.txt";`

`$plex_update_shell_file_log_location="/volume1/server-plex/web/logging/notifications/plex_update.txt";`

`$form_submit_location="index.php?page=6&config_page=plex_update";`

1. "use_sessions" configures the PHP page to require active session management or not. 
2. "plex_skip_versions_location" must be a dedicated folder for where the PHP page and script store details on PLEX versions that are being skipped. No other files should be in this folder. 
3. "config_file_location" is where the script reads the parameters controlled by the PHP web page. configure this for the desired location. make sure this value is also entered into the .sh file
4. "plex_update_shell_file_log_location" is where the log output of the .sh script file will be stored. 
5. "form_submit_location" is where the PHP submitted form data will be sent to. this file is meant to be called out from within another PHP file, in this case index.php. however the file can be used standalone and if so desired, this can be set to `plex_update_config.php` to have the data sent directly to the PHP file

### Configuration of synology web server "http" user permissions

by default the synology user "http" that web station uses does not have write permissions to the "web" file share. 

1. go to Control Panel -> User & Group -> "Group" tab
2. click on the "http" user and press the "edit" button
3. go to the "permissions" tab
4. scroll down the list of shared folders to find "web" and click on the right checkbox under "customize" 
5. check ALL boxes and click "done"
6. Verify the window indicates the "http" user group has "Full Control" and click the checkbox at the bottom "Apply to this folder, sub folders and files" and click "Save"

<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user1.png" alt="1313">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user2.png" alt="1314">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user3.png" alt="1314">

### PHP web-page Configuration and initialization 

Navigate to the PHP file address on the web server. Adjust the parameters available as desired. they will all be initialized to default values and the configuration file will be created.


### Configuration of Task Scheduler 

1. Control Panel -> Task Scheduler
2. Click ```Create -> Scheduled Task -> User-defined script```
3. Under "General Settings" name the script "PLEX Auto-Update" and choose the "root" user and ensure the task is enabled
4. Click the "Schedule" tab at the top of the window. in this example we will set it to run daily and will run at 11:00 PM
5. Configure to run daily 
6. Under Time, set "First run time" to "23" and "00"
7. under "Frequency" select "every day"
8. under last run time select "23:00"
9. go to the "Task Settings" tab
10. Ensure "Send run details by email" is checked and enter the email address to send the logs to. 
11. Under "Run command" enter ```bash /volumex/[shared_foler_name]/plex_backup.sh``` NOTE: ensure the ```/volumex/[shared_foler_name]/``` is where the script is located
12. click "ok" in the bottom right
13. IF desired, find the newly created task in your list, right click and select "run". when a confirmation window pops up, choose "yes". The script will run. 

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage Example


### Update Available
``` 
DSM version is 7.x.x
Current DSM Version Installed: 7.0.1
PLEX Update Installer

Latest PLEX Release Version: 1.25.3.5409
Currently Installed PLEX Version: 1.25.1.5286


New PLEX Version is Available -----> PlexMediaServer-1.25.3.5409-f11334058-x86_64_DSM7.spk
Package Date: Thu Jan 13 02:58:48 CST 2022
Package Age: 0 days
The PLEX package was released less than 14 days ago. PLEX update is being skipped for now

___________________________________
New Features:

*

___________________________________
Fixed Features:

* (Hubs) Fix potential serialization issue of CW hubs (#13237)
* (Metadata) Some episodes could fail to get metadata when using the legacy TVDB agent
* (Scanner) Hidden files inside media paths could cause unexpected issues with certain local assets (#13240)
* (Scanner) Improve detection of filename changes which should result in rematching items (#13220)
* (Scanner) Movie items with mis-matched agents could re-match unnecessarily during scanning (#13292)
* (Scanner) Some file paths could prevent movies from scanning in correctly (#12980)
* (Series Scanner) Improved matching of season directory names including codec or resolution details (#13235)
```

### Update Installed

```
DSM version is 7.x.x
Current DSM Version Installed: 7.0.1
PLEX Update Installer

Latest PLEX Release Version: 1.25.3.5409
Currently Installed PLEX Version: 1.25.1.5286


New PLEX Version is Available -----> PlexMediaServer-1.25.3.5409-f11334058-x86_64_DSM7.spk
Package Date: Thu Jan 13 02:58:48 CST 2022
Package Age: 5 days

Directory /volume1/Server2/Software/Software/PLEX is available, proceeding with package download

The package is older than 4 days --- > Downloading file PlexMediaServer-1.25.3.5409-f11334058-x86_64_DSM7.spk to the following location: /volume1/Server2/Software/Software/PLEX

File PlexMediaServer-1.25.3.5409-f11334058-x86_64_DSM7.spk downloaded successfully


waiting 30 seconds


Stopping PlexMediaServer....
{"action":"prepare","error":{"code":0},"stage":"prepare","success":true}

Plex was successfully shutdown

Installing PlexMediaServer version 1.25.3.5409....

Starting PlexMediaServer....
{"action":"prepare","error":{"code":0},"stage":"prepare","success":true}

Upgrade from: 1.25.1.5286
to: 1.25.3.5409 succeeded!

Moving PLEX installation file to the archive folder /volume1/Server2/Software/Software/PLEX/archive/
```

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## License

This is free to use code, use as you wish

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Your Name - Brian Wallace - wallacebrf@hotmail.com

Project Link: [https://github.com/wallacebrf/plex_update/blob/main/README.md)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

<p align="right">(<a href="#top">back to top</a>)</p>
