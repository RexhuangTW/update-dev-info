# Copyright (C) 2018 nestike.huang@gmail.com
# file: update_dev_info.sh
# update device list

FILE="/tmp/.update_info"
INTERFACE="br-lan"
ILLEGAL_ADDRESS="0.0.0.0"

if [ ! -f "$FILE" ]; then
        touch "$FILE"
else
        exit 0
fi

if [ ! -f "/etc/config/dev_info" ]; then
        touch /etc/config/dev_info
fi

if [ ! -f "/etc/config/dev_name" ]; then
        touch /etc/config/dev_name
fi

__dev_set()
{
        uci -q set dev_info."$1"=section
        uci -q set dev_info."$1".deviceMAC="$3"
        name=`uci get -q dev_name."$1".u_dev_name`
        if [ -z "$name" ]; then
                name=`cat /tmp/dhcp.leases | grep $3 | awk '{print $4}'`
        fi
        uci -q set dev_info."$1".online="1"
        uci -q set dev_info."$1".deviceIP="$2"
        uci -q set dev_info."$1".deviceName="$name"
        uci -q set dev_info."$1".from="$4"
}

ip neigh flush dev "$INTERFACE"
sleep 10
cat /proc/net/arp | grep "$INTERFACE" | awk '{print $1}' | while read ipaddress
do
        mac=`cat /proc/net/arp | grep "$ipaddress" | awk '{print $4}'`
        MAC=`echo "$mac" | sed 's/:/_/g'`
        bool_face_2G=`iwpriv ra0 show stainfo | if grep -iq "$mac";then echo yes;fi`
        if [ "yes" != "$bool_face_2G" ]; then
                bool_face_5G=`iwpriv rai0 show stainfo | if grep -iq "$mac";then echo yes;fi`
                if [ "yes" != "$bool_face_5G" ]; then
                        arping -I "$INTERFACE" -c 1 "$ipaddress" > /dev/null
                        if [ $? -eq 1 ]; then
                                /sbin/arp -d "$ipaddress"
                                uci -q delete dev_info."$MAC"
                        fi
                fi
        fi
done
uci -q commit dev_info
/sbin/arp -n -i "$INTERFACE" | awk '{print $4}' | sed -e '/incomplete/d' | while read mac
do
	ipaddress=`/sbin/arp -n -i "$INTERFACE" | grep "$mac" | sed 's/(//g' | sed 's/)//g' | awk '{print $2}'`
	echo $ipaddress | egrep '^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$'
	if [ $? -eq 0 ] && [ "$ipaddress" != "$ILLEGAL_ADDRESS" ]; then
		MAC=`echo "$mac" | sed 's/:/_/g'`
		bool_face_2G=`iwpriv ra0 show stainfo | if grep -iq "$mac";then echo yes;fi`
		if [ "yes" == "$bool_face_2G" ]; then
			__dev_set $MAC $ipaddress $mac "WLAN2G"
		else
			bool_face_5G=`iwpriv rai0 show stainfo | if grep -iq "$mac";then echo yes;fi`
			if [ "yes" == "$bool_face_5G" ]; then
				__dev_set $MAC $ipaddress $mac "WLAN5G"
			else
				__dev_set $MAC $ipaddress $mac "LAN"
			fi
		fi
	fi
done

uci commit dev_info

rm "$FILE"
