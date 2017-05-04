#!/bin/bash
#Copyright Angsuman Chakraborty, Taragana. Permission is granted for personal, non-commercial use.
#The script may not be re-distributed in any form without written permission from Angsuman Chakraborty ( angsuman@taragana.com ).
#The script may be modified for personal use.
#THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE AUTHOR ACCEPTS NO RESPONSIBILITY IN ANY CONCEIVABLE MANNER.

# Conventionally 0 indicates success in this script.

# Modified by dayer

# Sleep between checks, in seconds
SLEEPTIMEE=30
SLEEPTIMEI=5
SLEEPTIME=$SLEEPTIMEE

# Array to translate the 0 and 1 codes to a human language
TRADUCE[0]="OK"
TRADUCE[1]="NOK"

# IP to do ping
# DNS Google
TESTIP[0]=8.8.8.8
NOMBREIP[0]="DNS Google"
TESTIP[1]=8.8.4.4
NOMBREIP[1]="DNS Google"
# DNS OpenDNS
TESTIP[2]=208.67.222.222
NOMBREIP[2]="DNS OpenDNS"
TESTIP[3]=208.67.220.220
NOMBREIP[3]="DNS OpenDNS"
# DNS Level 3
TESTIP[4]=4.2.2.1
NOMBREIP[4]="DNS Level 3"
TESTIP[5]=4.2.2.2
NOMBREIP[5]="DNS Level 3"
# DNS Colt
TESTIP[6]=212.121.128.10
NOMBREIP[6]="DNS Colt"
TESTIP[7]=212.121.128.11
NOMBREIP[7]="DNS Colt"

# Last checked IP array index
TESTIPN=-1

# Array size
TESTIPT=${#TESTIP[@]}

# Ping timeout in seconds
TIMEOUT=2

# External interfaces
EXTIF1=isp1
EXTIF2=isp2

# Gateway IP addresses. This is the first (hop) gateway, could be your router IP 
# address if it has been configured as the gateway
GW1=85.56.0.1
GW2=192.168.1.1

# Broadband providers name; use your own names here.
NAME1=ISP1
NAME2=ISP2
NAME=DEFAULT

# Consecutive number of success or errors before change the connection status
SUCCESSREPEATCOUNT=$((TESTIPT/2+1))
FAILUREREPEATCOUNT=$((TESTIPT/2+1))

# Do not change anything below this line

# Last link status indicates the macro status of the link we determined. This is down initially to force routing change upfront. Don't change these values.
LLS1=1
LLS2=1
LLS=1

# Last ping status. Don't change these values.
LPS1=1
LPS2=1
LPS=1

# Current ping status. Don't change these values.
CPS1=1
CPS2=1
CPS=1

# Change link status indicates that the link needs to be changed. Don't change these values.
CLS1=1
CLS2=1
CLS=1

# Count of repeated up status or down status. Don't change these values.
COUNT1=0
COUNT2=0
COUNT=0

# Vars to prefered route
EXTIFP=""
GWP=""
NAMEP=""

IFP=""
function get_prefered_route {
	PRINT=$1

	IFP2=$(cat /etc/IFACE_prefered_ISP)
	if [ $? -ne 0 ]; then
		echo "Error reading the file '/etc/IFACE_prefered_ISP'. I'cant continue"
		exit 1
	fi

	# If it has not changed, we have not changed anything
	if [ "$IFP" == "$IFP2" ]; then
		return 0
	fi

	if [ $PRINT -ne 0 ]; then
		echo "prefered ISP iface changed from '$IFP' to '$IFP2'"
	fi
	IFP=$IFP2

	# We compare with the iface names which we know
	if [ "$IFP" == "$EXTIF1" ]; then
		EXTIFP=$EXTIF1
		GWP=$GW1
		NAMEP=$NAME1
	elif [ "$IFP" == "$EXTIF2" ]; then
		EXTIFP=$EXTIF2
		GWP=$GW2
		NAMEP=$NAME2
	else
		# In other case I must fail
		echo "I haven't configured the '$IFP' iface to use it as prefered route. This is an error and I die"
		exit 1
	fi

	# In this case the prefered route must change
	return 1
}

function reverse {
	if [ -z $1 ] || [ "$1" == 0 ]; then
		echo 1
	else
		echo 0
	fi
}

# To do pings from an ORIGINIP to an IP
# It returns 0 if goes well. In other case it returns 1
function do_ping {
	ping -W $TIMEOUT -I $1 -c 1 ${TESTIP[$TESTIPN]} > /dev/null  2>&1
	if [ "$?" -eq 0 ]; then
		return 0
	fi

	# In this case it has failed
	echo "Error in ping from $1 ($2) to ${TESTIP[$TESTIPN]} (${NOMBREIP[$TESTIPN]})"
	return 1
}


# To get the prefered route at startup
get_prefered_route 0

echo Starting monitor to control the routes to
echo "prefered ISP($NAMEP); External IPs($TESTIPT); Stable threshold($SUCCESSREPEATCOUNT); Unstable threshold($FAILUREREPEATCOUNT); Stable sleep($SLEEPTIMEE); Unstable sleep or error($SLEEPTIMEI)"

while : ; do
	# To calc the prefered route and if it's changed
	get_prefered_route 1
	CHANGE_FAV=$?

	# Inc. to next IP
	TESTIPN=$((TESTIPN+1))
	# Fix in case overflow the array
	if [ "$TESTIPN" -ge "$TESTIPT" ]; then
		TESTIPN=0
	fi

	# Reset the sleep
	SLEEPTIME=$SLEEPTIMEE

	do_ping $EXTIF1 $NAME1
        RETVAL=$?

        if [ "$RETVAL" -ne 0 ]; then
                CPS1=1
        else
                CPS1=0
        fi

        if [ "$LPS1" -ne "$CPS1" ]; then
                echo "Ping status for the $NAME1 route: changed from ${TRADUCE[$LPS1]} to ${TRADUCE[$CPS1]}"
		SLEEPTIME=$SLEEPTIMEI
                COUNT1=1
        else
                if [ "$LPS1" -ne "$LLS1" ]; then
			SLEEPTIME=$SLEEPTIMEI
                        COUNT1=`expr $COUNT1 + 1`
                fi
        fi

	# If the limit of success or errors has been exceeded
        if [[ $COUNT1 -ge $SUCCESSREPEATCOUNT || ($LLS1 -eq 0 && $COUNT1 -ge $FAILUREREPEATCOUNT) ]]; then
                echo "The STABILITY for the $NAME1 route would be changed from ${TRADUCE[$LLS1]} to ${TRADUCE[$(reverse $LLS1)]}"
		SLEEPTIME=$SLEEPTIMEE
                CLS1=0
                COUNT1=0
                if [ "$LLS1" -eq 1 ]; then
                        LLS1=0
                else
                        LLS1=1
                fi
        else 
                CLS1=1
        fi

        LPS1=$CPS1

	do_ping $EXTIF2 $NAME2
        RETVAL=$?

        if [ "$RETVAL" -ne 0 ]; then
                CPS2=1
        else
                CPS2=0
        fi

        if [ "$LPS2" -ne "$CPS2" ]; then
                echo "Ping status for the $NAME2 route: changed from ${TRADUCE[$LPS2]} a ${TRADUCE[$CPS2]}"
		SLEEPTIME=$SLEEPTIMEI
                COUNT2=1
        else
                if [ "$LPS2" -ne "$LLS2" ]; then
			SLEEPTIME=$SLEEPTIMEI
                        COUNT2=`expr $COUNT2 + 1`
                fi
        fi

        if [[ $COUNT2 -ge $SUCCESSREPEATCOUNT || ($LLS2 -eq 0 && $COUNT2 -ge $FAILUREREPEATCOUNT) ]]; then
                echo "The STABILITY for the $NAME2 route would be changed from ${TRADUCE[$LLS2]} to ${TRADUCE[$(reverse $LLS2)]}"
		SLEEPTIME=$SLEEPTIMEE
                CLS2=0
                COUNT2=0
                if [ "$LLS2" -eq 1 ]; then
                        LLS2=0
                else
                        LLS2=1
                fi
        else
                CLS2=1
        fi

        LPS2=$CPS2

	# Check the default route
	do_ping "0.0.0.0" "$NAME (por $NAMEP)"
	RETVAL=$?

	if [ "$RETVAL" -ne 0 ]; then
		CPS=1
	else
		CPS=0
	fi

	if [ "$LPS" -ne "$CPS" ]; then
		echo "Ping status for the $NAME  route(por $NAMEP): changed from ${TRADUCE[$LPS]} to ${TRADUCE[$CPS]}"
		SLEEPTIME=$SLEEPTIMEI
		COUNT=1
	else
	        if [ "$LPS" -ne "$LLS" ]; then
			SLEEPTIME=$SLEEPTIMEI
                        COUNT=`expr $COUNT + 1`
                fi
	fi

        if [[ $COUNT -ge $SUCCESSREPEATCOUNT || ($LLS -eq 0 && $COUNT -ge $FAILUREREPEATCOUNT) ]]; then
                echo "The STABILITY for the $NAME (route por $NAMEP) would be changed from ${TRADUCE[$LLS]} to ${TRADUCE[$(reverse $LLS)]}"
		SLEEPTIME=$SLEEPTIMEE
                CLS=0
                COUNT=0
                if [ $LLS -eq 1 ]; then
                        LLS=0
                else
                        LLS=1
                fi
        else
                CLS=1
        fi

        LPS=$CPS

	# If a change is detected it is checked it to establish the new routes
        if [[ $CLS1 -eq 0 || $CLS2 -eq 0 || $CLS -eq 0 || $CHANGE_FAV -eq 1 ]]; then
                if [[ $LLS1 -eq 1 && $LLS2 -eq 0 ]]; then 
                        echo "Changing prefered metric to $NAME2 and cleaning tracked connections with mark=1 ($NAME1's')"
			ip route replace default scope global via $GW2 dev $EXTIF2 metric 300
			conntrack -D --mark=1 1>/dev/null
                elif [[ $LLS1 -eq 0 && $LLS2 -eq 1 ]]; then
                        echo "Changing prefered metric to $NAME1 and cleaning tracked connections with mark=2 ($NAME2's')"
			ip route replace default scope global via $GW1 dev $EXTIF1 metric 300
			conntrack -D --mark=2 1>/dev/null
                elif [[ $LLS1 -eq 0 && $LLS2 -eq 0 ]]; then
                        echo Both connections are stables, prefered metric to the $NAMEP route
			ip route replace default scope global via $GWP dev $EXTIFP metric 300
                fi
        fi

        sleep $SLEEPTIME
done
