#!/bin/bash

# This script changes the prefered iface in "/etc/IFACE_PREFERED_ISP" and it works with Corosync
# The route-monitor.sh controls the file content and decides the change if it's necessary
# dayer 20170216

isp1="ISP1"
isp2="ISP2"
FILE="/etc/IFACE_PREFERED_ISP"

IF=$(cat $FILE)
if [ $? -ne 0 ]; then
	echo "Reading error with the file '$FILE'. I can't continue'"
	exit 1
fi

echo -e "\nAvailable ISP and its iface:\n\t-$isp1 (isp1)\n\t-$isp2 (isp2)\n"

echo "Current default routes (thw fewest is the prefered):"

ip route show | grep default

echo -e "\nThe current prefered is ${!IF} ($IF)"
echo -e "\n¿What do you want as the next ISP prefered? Write ISP1 or ISP2 and press enter:"

read new

echo ""
IFN=""

if [ "$new" == "$isp1" ]; then
	IFN="isp1"
elif [ "$new" == "$isp2" ]; then
	IFN="isp2"
else
	echo "The written ISP ($new) isn't correct. I don't change anything"
	exit 1
fi

echo $IFN > $FILE

echo -e "$new has been configured as prefered ISP.\n\nThis has modified the '$FILE' file.\nThe route monitor will detect the changes and will apply.\n"

OTHER=$(/usr/sbin/crm_node -l|grep -v $(hostname -s)|awk '{print $2}')
COPY="rsync -aAi --progress $FILE $OTHER:$FILE"

echo "Trying to copy the changes to other node ($OTHER):"
echo -e "$COPY\n"
$COPY

if [ "$?" -ne 0 ]; then
	echo "The copy to other node has failed. The changes must be copied manually"
	exit 1
fi

echo -e "\nChanges copied successfully to $OTHER"

exit 0
