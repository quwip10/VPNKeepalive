#!/bin/bash

#This is a keepalive script for OpenVPN clients
#This script will ping the server twice
#If successful, it will print such to syslog
#If it fails, it will restart the interface specified
#as well as the OpenVPN client service
#For this to work properly, the correct interface must be specified
#The OpenVPN client connection must also be set to autoconnect in:
#/etc/default/openvpn
#Use AUTOSTART="all"
#And ensure that the client.ovpn has been renamed client.conf and is
#stored in: /etc/openvpn

printf "VPNKeepalive Copyright (C) 2017  quwip10\nThis program comes with ABSOLUTELY NO WARRANTY;\nThis is free software, and you are welcome to redistribute it under certain conditions;\nSee the GNU General Public License v3.0 for more information\n"

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

printf "\nChecking if /etc/default/openvpn exists...\n"
sleep 2

if [ -f /etc/default/openvpn ];
then
	printf "\nOpenVPN default file exists."
else
	printf "\n/etc/default/openvpn does not exist.\n"
	printf "\nDo you want to install OpenVPN now? (y/n): "
	read yesno

	if [ $yesno == "y" ];
	then
#		sudo apt-get install openvpn
		printf "Installing OpenVPN\n"
		sleep 1
	else
		printf "\nThis script requires /etc/default/openvpn to run properly. Exiting\n"
		sleep 1
		exit
	fi

	sleep 1
fi


if [ -f ./customRestart.sh ];
then
	printf "customRestart.sh already exists in this directory! Exiting"
	sleep 2
	exit
fi

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
	sleep 1	
	printf "\nEnter primary network interface. (Your default route is using $interface)\n" 
	printf "Available interfaces: "
	echo $(/bin/ls /sys/class/net/)
	read interfaceIn
done

sleep 1

printf "\nEnter primary VPN Server Address (Default is 10.8.0.1): "
read serveraddressIn

if [ -z "$serveraddressIn" ];
then
	printf "Using default.\n"
else
	serveraddress=$serveraddressIn	
fi

sleep 1

printf "\nEnter log location (Default is /var/log/syslog): "
read logIn

if [ -z "$logIn" ];
then
	printf "Using default.\n"
else
	log=$logIn
fi

sleep 1

printf "\nUser to run cron jobs under. Enter for default. (Default is root): "
read cronuserIn

if [ -z "$cronuserIn" ];
then
	printf "Using default.\n"
else
	cronuser=$cronuserIn	
fi

sleep 1

printf "\nFrequency in minutes to run the script. Enter for default. (Default is 5 minutes): "
read cronfreqIn

if [ -z "$cronfreqIn" ];
then
	printf "Using default.\n"
else
	cronfreq=$confreqIn
fi

sleep 1

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
 
chmod 700 customRestart.sh

#(crontab -u $cronuser -l ; echo "*/$interval * * * * $scriptpath")| crontab -

printf "\nScript completed successfully.\nA new script customRestart.sh should now exist in your current directory.\nNOTE: This script cannot be moved or renamed or the cronjob will fail!\n \n"

sleep 2
