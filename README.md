# VPNKeepalive
(The master branch has been updated to now be fully interactive.)

(The original script can still be found at https://github.com/quwip10/VPNKeepalive/tree/original-script-archive )

**This script requires root/sudo priveleges to run!**

This script is designed to do self health checks by pinging the home VPN Server.
If the ping fails, the device will restart the interface (ifdown/ifup). Then it will
restart the OpenVPN client services.

Given the path to the client.ovpn it will automatically be renamed customScript.conf and placed in the /etc/openvpn/ 
directory.

Furthermore, the /etc/default/openvpn file will be automatically modified with the AUTOSTART="customScript" option added.

This script will automatically create a customized script based on the user input. It will place this script in the same directory as the original and it will automatically add the cronjob to run at the specified frequency. 

