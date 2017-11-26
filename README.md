# VPNKeepalive
This script is designed to do self health checks by pinging the home VPN Server.
If the ping fails, the device will restart the interface (ifdown/ifup). Then it will
restart the OpenVPN client services.

For this to work, the client.ovpn must be renamed client.conf and placed in the /etc/openvpn/ 
directory.

Furthermore, the /etc/default/openvpn file must have the AUTOSTART=ALL option enabled.

Future enhancements will make this all interactive.

It is designed to be a crontab job running as often as is necessary to poll the connection.

