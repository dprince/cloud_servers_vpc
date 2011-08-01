#!/bin/bash
set -u

export OPENVPN_DEVICE=${OPENVPN_DEVICE:-"tun"}
export OPENVPN_PROTO=${OPENVPN_PROTO:-"tcp"}
export OPENVPN_CONFIG_DIR=${OPENVPN_CONFIG_DIR:-"/etc/openvpn"}

function fail {
	echo $1
	exit 1
}

function create_client_config {

	if (( $# != 4 )); then
		echo "Failed to configure client for OpenVPN."
		echo "usage: create_client_config <server_ip> <vpn_ip> <client_name>."
		exit 1
	fi

local SERVER_IP=$1 #Example: 10.0.0.1
local VPN_IP=$2 #Example: 172.19.0.22
local CLIENT_NAME=$3 #Example client1
local DOMAIN_NAME=$4 #Example mydomain.net

mkdir -p "$OPENVPN_CONFIG_DIR/" 2> /dev/null
echo -n "Creating openvpn client config file..."
SCRIPT_SECURITY=""
openvpn --version | grep ' 2.1' &> /dev/null
if [ $? -eq 0 ]; then
	SCRIPT_SECURITY="script-security 3 system"
fi
cat > "$OPENVPN_CONFIG_DIR/$CLIENT_NAME.conf" <<-EOF_CAT
client
dev $OPENVPN_DEVICE
proto $OPENVPN_PROTO

#Change my.publicdomain.com to your public domain or IP address
remote $SERVER_IP 1194

resolv-retry infinite
nobind
persist-key
persist-tun

$SCRIPT_SECURITY

ca ca.crt
cert $CLIENT_NAME.crt
key $CLIENT_NAME.key

ns-cert-type server

comp-lzo

verb 3
up ./up.bash
down ./down.bash
EOF_CAT
[[ $? == 0 ]] || fail "Failed to create openvpn client config file."
echo "OK"

echo -n "Creating openvpn client up.bash..."
cat > "$OPENVPN_CONFIG_DIR/up.bash" <<-EOF_CAT
#!/bin/bash
mv /etc/resolv.conf /etc/resolv.conf.bak
cat > /etc/resolv.conf <<-"EOF_RESOLV_CONF"
search $DOMAIN_NAME
nameserver $VPN_IP
EOF_RESOLV_CONF
EOF_CAT
[[ $? == 0 ]] || fail "Failed to create up.bash."
chmod 755 $OPENVPN_CONFIG_DIR/up.bash
echo "OK"

echo -n "Creating openvpn client down.bash..."
cat > "$OPENVPN_CONFIG_DIR/down.bash" <<-EOF_CAT
#!/bin/bash
mv /etc/resolv.conf.bak /etc/resolv.conf
EOF_CAT
[[ $? == 0 ]] || fail "Failed to create down.bash."
chmod 755 $OPENVPN_CONFIG_DIR/down.bash
echo "OK"

if [ -f /etc/redhat-release ]; then
sed -e "s|^ONBOOT.*|ONBOOT=no|" -i /etc/sysconfig/network-scripts/ifcfg-eth0 || fail "Failed to disable eth0."
elif [ -f /etc/debian_version ]; then
sed -e "/^auto eth0.*/d" -i /etc/network/interfaces || fail "Failed to disable eth0."
else
echo "Failed to disable eth0"
return 1
fi

}

function init_client_etc_hosts {

	echo -n "Initializing /etc/hosts file with the internal client name..."
	if (( $# != 3 )); then
		echo "Failed to init etc hosts."
		echo "usage: init_client_etc_hosts <client name> <client internal ip>"
		exit 1
	fi

	local CLIENT_NAME=$1
	local CLIENT_DOMAIN=$2
	local CLIENT_IP=$3

	echo "127.0.0.1	localhost localhost.localdomain" > /etc/hosts
	echo "$CLIENT_IP	$CLIENT_NAME.$CLIENT_DOMAIN $CLIENT_NAME" >> /etc/hosts

	hostname "$CLIENT_NAME"
	if [ -f /etc/sysconfig/network ]; then
		sed -e "s|^HOSTNAME.*|HOSTNAME=$CLIENT_NAME|" -i /etc/sysconfig/network
	fi
	echo "OK"

}
