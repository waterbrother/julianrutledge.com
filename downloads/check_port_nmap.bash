#!/bin/bash

#usage: check_snmp_aix_cpuload.bash -H IP -C community -w warning -c critical
#description:this shell can fetch cpu load information by snmp protocol
#support check AIX5.3/AIX6.1/AIX7.1
#Written by Julian Rutledge, 2015-09-15
#adapted from check_snmp_aix_disk.sh 
#2014-06-25
#which was written by Helmet: blade2iron@gmail.com
#https://exchange.nagios.org/directory/Addons/SNMP/check_snmp_aix_disk-2Esh/details
#GPL - https://www.gnu.org/licenses/gpl.html


OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

PROGNAME=`basename $0`

ATTEMPTS=1

print_usage() {
    echo "Check if port is listening on host."
    echo "  "
	echo "  $PROGNAME"
	echo "            -H IP"
	echo "            -p TCP port"
	echo "            -a max number of attempts (must be > 0 and >= critical)"
	echo "            -w number of failed attempts until warning"
	echo "            -c number of failed attempts until critical"
	echo " "
	echo "  $PROGNAME -H 10.1.90.38 -p 1521 -a 5"
}

print_help() {
        echo ""
        print_usage
        echo ""
}

while [ -n "$1" ]
do
	case "$1" in 
		--help)
			print_help
			exit $UNKNOWN
			;;
		-h)
			print_help
			exit $UNKNOWN
			;;
		-H)
			HOSTNAME="$2"
			shift
			;;
		-p)
			PORT="$2"
			shift
			;;
		-a)
			ATTEMPTS="$2"
			shift
			;;
		-w)
			WARN_LEVEL="$2"
			shift
			;;
		-c)
			CRIT_LEVEL="$2"
			shift
			;;
		*)
			print_help
			exit $UNKNOWN
			;;
	esac
	shift
done

if [[ -n $HOSTNAME && -n $PORT && -n $WARN_LEVEL && -n $CRIT_LEVEL && $ATTEMPTS -gt 0 && $ATTEMPTS -ge $CRIT_LEVEL ]]; then
	
	TEST_COUNT=0
	FAIL_COUNT=0
	FAIL_MESSAGE=""
	until [[ $TEST_COUNT -eq $ATTEMPTS ]]; do
		RESPONSE=$( nmap -p $PORT $HOSTNAME | grep $PORT )
		if [[ -z $( echo $RESPONSE | grep "open" )  ]]; then
			FAIL_COUNT=`expr $FAIL_COUNT + 1`
			FAIL_MESSAGE=$(echo $RESPONSE | awk '{print $2}')
		fi
		#echo $RESPONSE
		sleep 1
		TEST_COUNT=`expr $TEST_COUNT + 1`
	done

	if [[ $FAIL_COUNT -ge $CRIT_LEVEL ]]; then
		echo "CRITICAL - Check on port $PORT failed with status \"$FAIL_MESSAGE\" $FAIL_COUNT times."
		exit $CRITICAL
	elif [[ $FAIL_COUNT -ge $WARN_LEVEL ]]; then
		echo "WARNING - Check on port $PORT failed with status \"$FAIL_MESSAGE\" $FAIL_COUNT times."
	elif [[ $FAIL_COUNT -lt $CRIT_LEVEL && $FAIL_COUNT -lt $CRIT_LEVEL ]]; then
		echo "OK - Port $PORT is open."
	else
		echo "UNKNOWN - Can't check port with nmap."
		exit $UNKNOWN
	fi
	
else 
	print_usage
	exit $UNKNOWN
fi
