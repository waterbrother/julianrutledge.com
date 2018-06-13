#!/bin/bash

#usage: check_snmp_aix_cpuload.bash -H IP -C community -w warning -c critical
#description:this shell can fetch cpu load information by snmp protocol
#support check AIX5.3/AIX6.1/AIX7.1/AIX7
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
CPU_LOAD_OID=".1.3.6.1.4.1.2.6.191.1.2.1.0"

print_usage() {
    echo "Usage: "
    echo "  $PROGNAME -H IP -C community -w warning -c critical"
		echo "  "
    echo "  Check CPU load on aix:"
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

	#get cpu load and exit status of command
	cpu_load=$( $SNMPWALK -v $snmpversion -c $COMMUNITY $HOSTNAME $CPU_LOAD_OID | awk -F: '{print $NF}' )
	snmp_exit_status=$?

	if [[ $snmp_exit_status -eq 0 ]] ; then
		
		if [[ -z $cpu_load ]]; then
			echo "UNKNOWN - Can't get CPU info through snmp | cpu_load=0"
			exit $UNKNOWN		
		elif [[ $cpu_load -ge $CRIT_LEVEL ]]; then
			echo "CRITICAL - CPU load is $cpu_load | cpu_load=$cpu_load"
			exit $CRITICAL
		elif [[ $cpu_load -ge $WARN_LEVEL ]]; then
			echo "WARNING - CPU load is $cpu_load | cpu_load=$cpu_load"
			exit $WARNING
		elif [[ $cpu_load -lt $WARN_LEVEL && $cpu_load -lt $CRIT_LEVEL ]];then
			echo "OK - CPU load is $cpu_load | cpu_load=$cpu_load"
			exit $OK
		else
			echo "UNKNOWN - Can't get CPU info through snmp | cpu_load=0"
			exit $UNKNOWN		
		fi
	else
		exit $UNKNOWN
	fi
	
else
	print_usage
	exit $UNKNOWN	
fi
