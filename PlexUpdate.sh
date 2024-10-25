#!/bin/bash

#version 10/23/2024
#By Brian Wallace

#this script now only supports DSM version 7.0 and higher. Support for DSM 6.x.x has been removed. 

#USER VARIABLES
lock_file_location="/volume1/web/logging/notifications/PlexUpdate.lock"
config_file_location="/volume1/web/config/config_files/config_files_local/plex_logging_variables.txt"
PMS_IP='192.168.1.200'
plex_installed_volume="volume1"
plex_installer_location="/volume1/Server2/Software/Software/PLEX"
log_file_location="/volume1/web/logging/notifications/plex_update.txt"
MSG='PLEX_Update_Installation_In_Progress'
plex_skip_versions_directory="/volume1/web/config/plex_versions"


#create a lock file in the ramdisk directory to prevent more than one instance of this script from executing  at once
if ! mkdir $lock_file_location; then
	echo "Failed to acquire lock.\n" >&2
	exit 1
fi
trap 'rm -rf $lock_file_location' EXIT #remove the lockdir on exit


counter=0
sendmail_installed=0
if [ -r "$config_file_location" ]; then
	#file is available and readable
	read input_read < $config_file_location #determine how many minutes it has been since the last "disk0" email has been sent
	explode=(`echo $input_read | sed 's/,/\n/g'`)
	plex_pass_beta=${explode[0]} # set to "1" to download PLEX-PASS enabled BETA versions. Set to "0" to download the public release versions. Public Release Versions tend to be more stable
	minimim_package_age=${explode[1]} #number of days the package must be released before it is downloaded
	email_address=${explode[2]} #email address to send logs /results to
	#fix_bad_driver=${explode[3]} #known intel driver issue with Gemini Lake processors on synology, seems to be fixed now as of 1/18/2022
	script_enable=${explode[4]} #completely disable the script?
	skip_version=0
	from_email_address=${explode[5]}


	if [ $script_enable -eq 1 ] 
	then
	
		#verify MailPlus Server package is installed and running as the "sendmail" command is not installed in synology by default. the MailPlus Server package is required
		install_check=$(/usr/syno/bin/synopkg list | grep MailPlus-Server)

		if [ "$install_check" = "" ];then
			echo "WARNING!  ----   MailPlus Server NOT is installed, cannot send email notifications"
			sendmail_installed=0
		else
			#echo "MailPlus Server is installed, verify it is running and not stopped"
			status=$(/usr/syno/bin/synopkg is_onoff "MailPlus-Server")
			if [ "$status" = "package MailPlus-Server is turned on" ]; then
				sendmail_installed=1
			else
				sendmail_installed=0
				echo "WARNING!  ----   MailPlus Server NOT is running, cannot send email notifications"
			fi
		fi
		
		#setup email notification details in beginning of file (from, to, and subject lines) so we can send the results of the script to an email address 
		echo "from: $from_email_address " > $log_file_location
		echo "to: $email_address " >> $log_file_location
		echo "subject: Server-PLEX PLEX Update Available " >> $log_file_location
		echo "" >> $log_file_location
	
		#determine DSM version to ensure the DSM7.x vs DSM 7.2.2 version of the synology PLEX package is downloaded
		DSMVersion=$(                   cat /etc.defaults/VERSION | grep -i 'productversion=' | cut -d"\"" -f 2)

		echo "" |& tee -a $log_file_location
		MinDSMVersion=7.2.2
		/usr/bin/dpkg --compare-versions "$MinDSMVersion" gt "$DSMVersion"
		if [ "$?" -eq "0" ]; then
			dsm_type="Synology (DSM 7)"
			echo "DSM version is between 7.0 and 7.2.1" |& tee -a $log_file_location
			echo "Current DSM Version Installed: $DSMVersion" |& tee -a $log_file_location
			plex_package_name="PlexMediaServer"
			plex_directory_name="PlexMediaServer"
			plex_Preferences_loction="$plex_directory_name/AppData/Plex Media Server/Preferences.xml"
		else
			dsm_type="Synology (DSM 7.2.2+)"
			echo "DSM version is 7.2.2 or Higher" |& tee -a $log_file_location
			echo "Current DSM Version Installed: $DSMVersion" |& tee -a $log_file_location
			plex_package_name="PlexMediaServer"
			plex_directory_name="PlexMediaServer"
			plex_Preferences_loction="$plex_directory_name/AppData/Plex Media Server/Preferences.xml"
		fi

		#beginning of email message body
		echo "PLEX Update Installer" |& tee -a $log_file_location

		if [ $plex_pass_beta -eq 1 ]
		then
			#get the plex token to allow logging into the plex-pass site to download the latest PLEX version
			token=$(cat "/$plex_installed_volume/$plex_Preferences_loction" | grep -oP 'PlexOnlineToken="\K[^"]+')

			#append the PLEX token to the PLEX download URL
			url=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$token")
		else
			url=$(echo "https://plex.tv/api/downloads/5.json")
		fi

		jq=$(curl -s ${url})

		#determine the version of the latest release of PLEX
		newversion=$(echo $jq | jq -r '.nas."'"${dsm_type}"'".version')
		explode=(`echo $newversion | sed 's/-/\n/g'`)
		newversion=${explode[0]}

		#display the latest version of PLEX
		echo |& tee -a $log_file_location
		echo "Latest PLEX Release Version: $newversion" |& tee -a $log_file_location

		#determine the version of PLEX currently installed on the system
		curversion=$(synopkg version "$plex_package_name")
		
		explode=(`echo $curversion | sed 's/-/\n/g'`)
		curversion=${explode[0]}

		#display the version of PLEX currently installed on the system
		echo "Currently Installed PLEX Version: $curversion" |& tee -a $log_file_location

		#determine if the version installed on the system is different from the version on line
		if [ "$newversion" != "$curversion" ]
		then
			
			#PLEX is available in both 32 bit and 64 bit versions. determine the CPU type of the system
			CPU=$(uname -m)
			
			#update the URL where the PLEX installer file will be downloaded from to match the CPU type of the system
			url=$(echo "${jq}" | jq -r '.nas."'"${dsm_type}"'".releases[] | select(.build=="linux-'"${CPU}"'") | .url')
			package="${url##*/}" #determine only the file name being downloaded 
			
			NewVerAddd=$(echo $jq | jq                                -r '.nas."'"${dsm_type}"'".items_added')
			NewVerFixd=$(echo $jq | jq                                -r '.nas."'"${dsm_type}"'".items_fixed')
			
			#determine how old the release is
			UpdateDate=$(curl -s -v --head $url 2>&1 | grep -i '^< Last-Modified:' | cut -d" " -f 3-)
			UpdateDate=$(date --date "$UpdateDate" +'%s')
			TodaysDate=$(date --date "now" +'%s')
			UpdateEpoc=$((($TodaysDate-$UpdateDate)/86400))
			
			#the version on-line does not match what is currently installed -- an update is available
			echo |& tee -a $log_file_location
			echo "" |& tee -a $log_file_location
			echo "New PLEX Version is Available -----> $package" |& tee -a $log_file_location
			echo   "Package Date: $(date --date "@$UpdateDate")" |& tee -a $log_file_location
			echo   "Package Age: $UpdateEpoc days" |& tee -a $log_file_location
			
			
			FILE=$plex_skip_versions_directory/$newversion.skip
			#if file exists, then it has been marked to be skipped
			if [ -f "$FILE" ]; then
				skip_version=1
			fi
			
			if [ $skip_version -eq 0 ]; then
				#check if the update is older than the minimum package age. 
				if [ $UpdateEpoc -ge $minimim_package_age ]; then
				
				
					#since the file is being saved to a network file share, let's make sure the network is available
					if [ ! -d $plex_installer_location ] ; then
						echo ""  |& tee -a $log_file_location
						echo "Error directory $plex_installer_location is not available, exiting script" |& tee -a $log_file_location
						exit 1	
					else
						echo ""  |& tee -a $log_file_location
						echo "Directory $plex_installer_location is available, proceeding with package download" |& tee -a $log_file_location
					fi
			
					#####################################
					#proceed with downloading the package 
					#####################################
					echo |& tee -a $log_file_location
					echo "The package is older than $minimim_package_age days --- > Downloading file $package to the following location: $plex_installer_location" |& tee -a $log_file_location
										
					/bin/wget $url -nc -P $plex_installer_location
					if [ $? -ne 0 ]
					then
						echo "Error Downloading File exiting script" |& tee -a $log_file_location
						exit 1						
					fi
					
					if [ -r "$plex_installer_location/$package" ]; then
						echo ""  |& tee -a $log_file_location
						echo "File $package downloaded successfully" |& tee -a $log_file_location
						echo ""  |& tee -a $log_file_location
					else
						echo ""  |& tee -a $log_file_location
						echo "Error Downloading File exiting script" |& tee -a $log_file_location
						exit 1
					fi
				
					#####################################
					#now that the package is downloaded, stop PLEX on the system so the update can be installed
					#####################################
				
				
					#####################################
					#first lets terminate any active sessions
					#####################################
				
					CLIENT_IDENT='123456'

					#Start by getting the active sessions

					sessionURL="http://$PMS_IP:32400/status/sessions?X-Plex-Client-Identifier=$CLIENT_IDENT&X-Plex-Token=$token"
					response=$(curl -i -k -L -s $sessionURL)
					sessions=$(printf %s "$response"| grep '^<Session*'| awk -F= '$1=="id"{print $2}' RS=' '| cut -d '"' -f 2)

					# Active sessions id's now stored in sessions variable, so convert to an array
					set -f                      # avoid globbing (expansion of *).
					array=(${sessions//:/ })
					for i in "${!array[@]}"
					do
						echo "PLEX Active - Need to kill session: ${array[i]}" |& tee -a $log_file_location
						killURL="http://$PMS_IP:32400/status/sessions/terminate?sessionId=${array[i]}&reason=$MSG&X-Plex-Client-Identifier=$CLIENT_IDENT&X-Plex-Token=$token"
						# Kill it
						response=$(curl -i -k -L -s $killURL)
						# Get response
						http_status=$(echo "$response" | grep HTTP |  awk '{print $2}')
						#echo $killURL |& tee -a $log_file_location
						if [ $http_status -eq "200" ]
						then
							echo "Success with killing of stream ${array[i]}" |& tee -a $log_file_location
						else
							echo "Something went wrong here" |& tee -a $log_file_location
						fi
					done
					echo "" |& tee -a $log_file_location
					#####################################
					#Stop plex package
					#####################################
				
				
					echo |& tee -a $log_file_location
					plex_status=$(/usr/syno/bin/synopkg is_onoff "$plex_package_name")
					if [ "$plex_status" = "package $plex_package_name is turned on" ]; then
						echo |& tee -a $log_file_location
						echo "Stopping $plex_package_name...." |& tee -a $log_file_location
						/usr/syno/bin/synopkg stop "$plex_package_name" |& tee -a $log_file_location
					else
						echo "$plex_package_name Already Shutdown" |& tee -a $log_file_location
					fi
					sleep 1
					
					#####################################
					#verify the package successfully stopped
					#####################################
					
					plex_status=$(/usr/syno/bin/synopkg is_onoff "$plex_package_name")

					if [ "$plex_status" = "package $plex_package_name is turned on" ]; then
						echo |& tee -a $log_file_location
						echo "$plex_package_name Shutdown Failed, Skipping PLEX Update Process" |& tee -a $log_file_location
						exit 1
					else
						echo |& tee -a $log_file_location
						echo "Plex was successfully shutdown" |& tee -a $log_file_location
					fi
				
					#####################################
					#install the update
					#####################################
					echo |& tee -a $log_file_location
					echo "Installing $plex_package_name version $newversion...." |& tee -a $log_file_location
					/usr/syno/bin/synopkg install $plex_installer_location/$package |& tee -a $log_file_location
					sleep 1
				
					#####################################
					#start PlexMediaServer Package 
					#####################################
					plex_status=$(/usr/syno/bin/synopkg is_onoff "$plex_package_name")
					if [ "$plex_status" = "package $plex_package_name is turned on" ]; then
						echo "PLEX already active, skipping PLEX restart" |& tee -a $log_file_location
					else
						echo |& tee -a $log_file_location
						echo "Starting $plex_package_name...." |& tee -a $log_file_location
						/usr/syno/bin/synopkg start "$plex_package_name" |& tee -a $log_file_location
						sleep 1
					fi
				
					#####################################
					#verify the installation was successful. ask for the version of PLEX now installed and compare that to the version that was previously installed
					#####################################
					nowversion=$(synopkg version "$plex_package_name")
					explode=(`echo $nowversion | sed 's/-/\n/g'`)
					nowversion=${explode[0]}
				  
					if [ "$nowversion" == "$newversion" ]; then
				  
						#the version now installed is not the same version that was previously installed, the installation of the update appears to be a success
						echo  |& tee -a $log_file_location
						echo "Upgrade from: $curversion" |& tee -a $log_file_location
						echo "to: $newversion succeeded! Current Version reported as $nowversion" |& tee -a $log_file_location
						echo  |& tee -a $log_file_location
					
						#now that PLEX has been updated, the installation file is no longer needed, move the file to a archive location allowing the file to be available if PLEX must be downgraded to a previous version in the future
						echo "Moving PLEX installation file to the archive folder $plex_installer_location/archive/" |& tee -a $log_file_location
						echo |& tee -a $log_file_location
						
						#check the directory is available
						if [ ! -d $plex_installer_location/archive ] ; then
							mkdir -p $plex_installer_location/archive |& tee -a $log_file_location
							echo "Directory $plex_installer_location/archive has been created" |& tee -a $log_file_location
						fi
						
						mv $plex_installer_location/$package $plex_installer_location/archive/$package |& tee -a $log_file_location
					else
				  
						#the version now installed is the same that was previously installed so the installation was a failure 
						echo  |& tee -a $log_file_location
						echo "Upgrade from: $curversion" |& tee -a $log_file_location
						echo "to: $newversion failed! Current Version reported as $nowversion" |& tee -a $log_file_location
						echo  |& tee -a $log_file_location
						echo "The currently installed version of PLEX is still $nowversion" |& tee -a $log_file_location
						echo  |& tee -a $log_file_location
					fi
				else
					echo "The PLEX package was released less than $minimim_package_age days ago. PLEX update is being skipped for now" |& tee -a $log_file_location
					echo "" |& tee -a $log_file_location
					echo "___________________________________" |& tee -a $log_file_location
					echo "New Features:"  |& tee -a $log_file_location
					echo "" |& tee -a $log_file_location
					echo "$NewVerAddd" | awk '{ print "* " $0 }' |& tee -a $log_file_location
					echo "" |& tee -a $log_file_location
					echo "___________________________________" |& tee -a $log_file_location
					echo "Fixed Features:"  |& tee -a $log_file_location
					echo "" |& tee -a $log_file_location
					echo "$NewVerFixd" | awk '{ print "* " $0 }'  |& tee -a $log_file_location
				fi
			else 
				echo "The PLEX Version has been marked as skipped, the update will not be installed" |& tee -a $log_file_location
			fi
			let counter=counter+1
		else

			#no new plex version is available
			echo |& tee -a $log_file_location
			echo "No PLEX Updates Available" |& tee -a $log_file_location
			echo |& tee -a $log_file_location
			counter=0
		fi
	else
		echo "Script Currently Disabled. Skipping Plex Update Process" |& tee -a $log_file_location
		let counter=counter+1
	fi

	if [ $counter -ne 0 ]
	then
		if [ $skip_version -eq 0 ]
		then
			if [ $sendmail_installed -eq 1 ];then
				#send an email with the results of the script 
				cat $log_file_location | sendmail -t
			else
				echo "Could not send email of logs saved to \"$log_file_location\". Please check logs manually"
			fi
		else
			echo "skipping email send as version has been marked to be skipped" |& tee -a $log_file_location
		fi
	else
		echo "No Updates available, skipping email send" |& tee -a $log_file_location
	fi
else
	echo "Configuration file unavailable" |& tee -a $log_file_location
fi
