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



PATH="/usr/bin:/usr/sbin:/bin:/sbin"
LIBEXEC="/usr/local/nagios/libexec"

OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

snmpversion=1
PROGNAME=`basename $0`
SNMPWALK="/usr/bin/snmpwalk"

#the OID of disk information
PAGE_PCT_USED_OID=".1.3.6.1.4.1.2.6.191.2.4.2.1.5"
PAGE_PCT_USED_OID=".1.3.6.1.4.1.2.6.191.2.4.2.1.5"

print_usage() {
    echo "Usage: "
    echo "  $PROGNAME -H IP -C community -w warning -c critical"
		echo "  "
    echo "  Check Pagefile usage on aix:"
		echo " "
		echo "    $PROGNAME -H IP -C community -w warning -c critical "
		echo "    $PROGNAME -H 10.1.90.38 -C cebpublic -w 80 -c 90"
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
		-C)
			COMMUNITY="$2"
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

if [[ -n $HOSTNAME && -n $COMMUNITY && -n $WARN_LEVEL && -n $CRIT_LEVEL ]] ; then 

	#get page percent used and exit status of command
	response=$( $SNMPWALK -v $snmpversion -c $COMMUNITY $HOSTNAME $PAGE_PCT_USED_OID )
	pg_pct_used=$( echo $response | awk -F: '{print $NF}' )
	#echo $response
	#echo $pg_pct_used

	if [[ -n $pg_pct_used  ]] ; then
		
		if [[ $pg_pct_used -ge $CRIT_LEVEL ]]; then
			echo "CRITICAL - Pagefile usage percent is $pg_pct_used"
			exit $CRITICAL
		elif [[ $pg_pct_used -ge $WARN_LEVEL ]]; then
			echo "WARNING - Pagefile usage percent is $pg_pct_used"
			exit $WARNING
		elif [[ $pg_pct_used -lt $WARN_LEVEL && $pg_pct_used -lt $CRIT_LEVEL ]];then
			echo "OK - Pagefile usage percent is $pg_pct_used"
			exit $OK
		else
			echo "UNKNOWN - Can't get Pagefile usage info through snmp"
			exit $UNKNOWN		
		fi
	else
		echo "UNKNOWN - Can't get Pagefile usage info through snmp"
		exit $UNKNOWN
	fi
	
else
	print_usage
	exit $UNKNOWN	
fi
