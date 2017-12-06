#!/bin/bash

#This is a keepalive script for OpenVPN clients
#This script will ping the server twice
#If successful, it will print such to syslog
#If it fails, it will restart the interface specified
#as well as the OpenVPN client service
#For this to work properly, the correct interface must be specified
#The OpenVPN client connection must also be set to autoconnect in:
#/etc/default/openvpn
#Use AUTOSTART="all" or AUTOSTART="CONFIGNAME"
#And ensure that the client.ovpn has been renamed client.conf and is
#stored in: /etc/openvpn

#This will ensure that the script is running with root priveleges
#and will exit if not

if [ $EUID -ne 0 ];
then
	printf "\nPlease run with sudo/root priveleges. Exiting...\n\n"
	sleep 1
	exit 
fi

#Ths just prints the license info
printf "\nVPNKeepalive Copyright (C) 2017  quwip10\nThis program comes with ABSOLUTELY NO WARRANTY;\nThis is free software, and you are welcome to redistribute it under certain conditions;\nSee the GNU General Public License v3.0 for more information\n"

#Script to ping server

#Global Variables
now=$(date)
#Below line commented out due to bug finding that $6 is not always the correct word number to display the interface.
#interface=$(/sbin/ip -o -4 route show to default |awk '{print $6}')
interface=$(/sbin/ip -o -4 route show to default |awk '{print $5 " " $6}')
serveraddress=10.8.0.1
log=/var/log/syslog
scriptpath=$(pwd)/customRestart.sh
cronuser=root
cronfreq=5
ovpnPath=

#This procedure checks if the customRestart.sh script already exists
#If it does it prompts the user to reset the previous changes or exit
if [ -f ./customRestart.sh ];
then
	printf "\ncustomRestart.sh already exists in this directory! \n"
	sleep 1
	printf "\nWould you like to reset/remove ALL changes previously made by this script? (y/n) "
	read yesno
	
	if [ $yesno == "y" ];
	then
		if [ -f /etc/openvpn/customScript.conf ];
		then
			if [ -f /etc/openvpn/customScript.conf ]
			then
				mv /etc/openvpn/customScript.conf /etc/openvpn/customScript.bak
			fi
		fi	
		
		if [ -f /etc/default/openvpn ]
		then
			sed -i.bak /customScript/d /etc/default/openvpn
		fi
		
		mv ./customRestart.sh ./customRestart.sh.bak

		printf 'User to remove crontab entry from (Enter for default [root]): '
		read cronuserIn

		if [ -z "$cronuserIn" ];
		then
			printf "Using default.\n"
		else

			until  id $cronuserIn >/dev/null 2>&1 && [ ! -z "$cronuserIn" ];
			do
				printf "\nPlease enter a valid user.\n"
				sleep 0.5	
				printf "\nUser to run cron jobs under. (Default is root): "
				read cronuserIn
			done

			cronuser=$cronuserIn	
		fi
		
		printf "\nCleaning up...\n"
		(crontab -u $cronuser -l| grep -v 'customRestart.sh' |crontab -u $cronuser -)
		sleep 2
		printf "\nRenamed related files with .bak extension.\n\n"
		exit

	else
		printf "\nExiting\n"
		exit
	fi
fi

#The below checks to see if /etc/default/openvpn exists
#This dir is required for automated OpenVPN connections
#If it does not exist, it will prompt the user to install

#***Note, in the event that OpenVPN has been previously installed
#but is then uninstalled, the dir will exist, but the cron script
#will repeatedly run and fail since OpenVPN will never start...

printf "\nChecking if /etc/default/openvpn exists...\n"
sleep 1

if [ -f /etc/default/openvpn ];
then
	printf "\nOpenVPN default file exists!\n"
else
	printf "\n/etc/default/openvpn does not exist.\n"
	printf "\nDo you want to install OpenVPN now? (y/n): "
	read yesno

	if [ $yesno == "y" ];
	then
		apt-get install openvpn
		printf "Installing OpenVPN\n"
		sleep 0.5
	else
		printf "\nThis script requires /etc/default/openvpn to run properly. Exiting\n"
		sleep 1
		exit
	fi

	sleep 0.5
fi

#This procedure will take in the path to the .conf or .ovpn file
#It will check that it is a valid file path
printf "\nEnter full path to the CLIENT.conf or .ovpn file: "
read ovpnPath

until [ -f $ovpnPath ] && [ ! -z $ovpnPath ];
do
	printf "\nPlease enter a valid file path.\n"
	printf "\nEnter full path to the CLIENT.conf or .ovpn file: "
	read ovpnPath
done

#This reads in the network interface.
#It cannot be empty but there is currently no other validation check

printf "\nEnter primary network interface. (Your default route is using $interface)\n" 
printf "Available interfaces: "
echo $(/bin/ls /sys/class/net/)
read interfaceIn

#if [ -z "$interfaceIn" ];
#then
#	printf "Using default.\n"
#else
#	interface=$interfaceIn
#fi

until [ ! -z "$interfaceIn" ];
do
	printf "\nYou must enter an interface.\n"
	sleep 0.5
	printf "\nEnter primary network interface. (Your default route is using $interface)\n" 
	printf "Available interfaces: "
	echo $(/bin/ls /sys/class/net/)
	read interfaceIn
done

interface=$interfaceIn

sleep 0.5

#Takes in the IP address to ping

printf "\nEnter primary VPN Server Address (Default is 10.8.0.1): "
read serveraddressIn

if [ -z "$serveraddressIn" ];
then
	printf "Using default.\n"
else
	serveraddress=$serveraddressIn	
fi

sleep 1

#Takes in the log location

printf "\nEnter log location (Default is /var/log/syslog): "
read logIn

if [ -z "$logIn" ];
then
	printf "Using default.\n"
else
	log=$logIn
fi

sleep 1

#Takes in the user to run the cronjob under
#Validates that it is a valid user

printf "\nUser to run cron jobs under. Enter for default. (Default is root): "
read cronuserIn

if [ -z "$cronuserIn" ];
then
	printf "Using default.\n"
else
	until  id $cronuserIn >/dev/null 2>&1;
	do
		printf "\nPlease enter a valid user.\n"
		sleep 0.5	
		printf "\nUser to run cron jobs under. Enter for default. (Default is root): "
		read cronuserIn
	done

	cronuser=$cronuserIn	
fi

sleep 1

#Takes in the frequency to run the script
#Validates that it must be an integer

printf "\nFrequency in minutes to run the script. Enter for default. (Default is 5 minutes): "
read cronfreqIn

if [ -z "$cronfreqIn" ];
then
	printf "Using default.\n"
else
	until [[ "$cronfreqIn" =~ ^[0-9]+$ ]];
	do
		printf "\nMust be an integer.\n\nFrequency in minutes to run the script: "
		read cronfreqIn
	done

	cronfreq=$cronfreqIn
fi

sleep 1

printf "\n Below is a summary of changes to be committed: \n"

printf "\nInterface to monitor: $interface\n"
printf "Server to ping for keepalives: $serveraddress\n"
printf "Log location: $log\n"
printf "User to run cronjob as: $cronuser\n"
printf "Frequency to run cronjob/keepalive: $cronfreq\n"
printf "Location of client.conf or client.ovpn: $ovpnPath\n"

printf "\nIs this correct? (y to commit, anything else to exit): "
read yesno

if [ $yesno == "y" ];
then
	printf "\nBuilding custom script...\n"
else
	exit
fi

#Execute changes.

if [ ! -z "$ovpnPath" ];
then
	cp $ovpnPath /etc/openvpn/customScript.conf
	echo -e "AUTOSTART=\"customScript\"" >> /etc/default/openvpn
fi



#The below lines write out to a custom script for the user called customRestart.sh
echo '#!/bin/bash' >> customRestart.sh
echo "#Autogenerated OpenVPN Keepalive cron script\n" >> customRestart.sh
echo 'now=$(date)' >> customRestart.sh
echo "if ping -c 2 $serveraddress &> /dev/null;" >> customRestart.sh
echo 'then' >> customRestart.sh
echo "	echo \"\$now OpenVPN keepalive successful\" >> $log" >> customRestart.sh
echo 'else' >> customRestart.sh
echo "	echo \"\$now OpenVPN keepalive failed\" >> $log" >> customRestart.sh
echo "	echo \"\$now Restarting Networking\" >> $log" >> customRestart.sh
echo "	/sbin/ifdown $interface" >> customRestart.sh
echo "	/sbin/ifup $interface" >> customRestart.sh
echo '	sleep 30' >> customRestart.sh 
echo "	echo \"\$now Restarting OpenVPN\" >> $log" >> customRestart.sh
echo "	/etc/init.d/openvpn restart >> $log" >> customRestart.sh
echo 'fi' >> customRestart.sh
 
#Make the new script executable
chmod 700 customRestart.sh

#This line prints the crontab for the selected user, adds an entry for the custom script,
#and reinstalls the crontab
{ sudo crontab -l -u $cronuser; echo "*/$cronfreq * * * * $scriptpath"; }| crontab -u $cronuser -

sleep 1

printf "\nScript completed successfully.\nA new script customRestart.sh should now exist in your current directory.\nNOTE: This script cannot be moved or renamed or the cronjob will fail!\n \n"

sleep 2
