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
SNMPWALK="/usr/bin/snmpwalk"

#the OID of disk information
TOTAL_SWAP_OID=".1.3.6.1.4.1.2021.4.3.0"
SWAP_AVAIL_OID=".1.3.6.1.4.1.2021.4.4.0"

print_usage() {
    echo "Check amount of swap used on Linux host."
    echo "Swap usage is counted in kilobytes."
    echo "  "
    echo "SNMP v3 usage (secure): "
	echo "  $PROGNAME"
	echo "            -H IP"
	echo "            -u user"
	echo "            -A authenication_pass"
	echo "            -X encryption_pass"
	echo "            -a authenication_type"
	echo "            -x encrytion_tpye"
	echo "            -w warning"
	echo "            -c critical"
	echo "  Example: "
	echo "  $PROGNAME -H 10.1.90.38 -u snmpuser -A iamauthenticated -X iamencrypted -a md5 -x AES -w 512 -c 1024"
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
		-u)
			SNMP_USER="$2"
			shift
			;;
		-A)
			AUTH_PASS="$2"
			shift
			;;
		-X)
			ENCRYPT_PASS="$2"
			shift
			;;
		-a)
			AUTH_TYPE="$2"
			shift
			;;
		-x)
			ENCRYPT_TYPE="$2"
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

if [[ -n $HOSTNAME && -n $SNMP_USER && -n $AUTH_PASS && -n $ENCRYPT_PASS && -n $AUTH_TYPE && -n $ENCRYPT_TYPE && -n $WARN_LEVEL && -n $CRIT_LEVEL ]]; then
	SYSTEM_TOTAL_SWAP=$( $SNMPWALK -v 3 -u $SNMP_USER -A $AUTH_PASS -a $AUTH_TYPE -X $ENCRYPT_PASS -x $ENCRYPT_TYPE -l authPriv $HOSTNAME $TOTAL_SWAP_OID | awk -F: '{print $NF}' | awk '{ print $1 }')
	TOTAL_SWAP_EXIT_STATUS=$?
	SYSTEM_AVAIL_SWAP=$( $SNMPWALK -v 3 -u $SNMP_USER -A $AUTH_PASS -a $AUTH_TYPE -X $ENCRYPT_PASS -x $ENCRYPT_TYPE -l authPriv $HOSTNAME $SWAP_AVAIL_OID | awk -F: '{print $NF}' | awk '{ print $1 }')
	AVAIL_SWAP_EXIT_STATUS=$?

	if [[ $TOTAL_SWAP_EXIT_STATUS -eq 0 && $AVAIL_SWAP_EXIT_STATUS -eq 0 ]] ; then
#		echo "total swap: $SYSTEM_TOTAL_SWAP"
#		echo "avail swap: $SYSTEM_AVAIL_SWAP"
		SYSTEM_SWAP_USED=`expr $SYSTEM_TOTAL_SWAP - $SYSTEM_AVAIL_SWAP`
		if [[ $SYSTEM_SWAP_USED -ge $CRIT_LEVEL ]]; then
			echo "CRITICAL - swap usage is $SYSTEM_SWAP_USED kB out of $SYSTEM_TOTAL_SWAP kb"
			exit $CRITICAL
		elif [[ $SYSTEM_SWAP_USED -ge $WARN_LEVEL ]]; then
				echo "WARNING - swap usage is $SYSTEM_SWAP_USED kB out of $SYSTEM_TOTAL_SWAP kb"
				exit $WARNING
		elif [[ $SYSTEM_SWAP_USED -lt $CRIT_LEVEL && $SYSTEM_SWAP_USED -lt $WARN_LEVEL ]]; then
				echo "OK - swap usage is $SYSTEM_SWAP_USED kB out of $SYSTEM_TOTAL_SWAP kb"
		else
			echo "UNKNOWN - Can't get swap usage through snmp"
			exit $UNKNOWN
		fi			
	else
		exit $UNKNOWN
	fi

else 
	print_usage
	exit $UNKNOWN
fi
