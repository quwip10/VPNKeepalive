#!/bin/bash

#This is a keapalive script for my OpenVPN clients
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

#Script to ping server

#Global Variables
now=$(date)
interface=wlan0
serveraddress=10.8.0.1
log=/var/log/syslog

if ping -c 2 $serveraddress &> /dev/null;
then
	echo "$now OpenVPN keepalive successful" >> $log
else
	echo "$now OpenVPN keepalive failed" >> $log
	echo "$now Restarting Networking" >> $log
	/sbin/ifdown $interface
	/sbin/ifup $interface
	sleep 30 

	echo "$now Restarting OpenVPN" >> /var/log/syslog
	/etc/init.d/openvpn restart >> /var/log/syslog
fi
 
