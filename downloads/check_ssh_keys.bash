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
    echo "Check if ssh login is successful."
    echo "Assumes you have ssh keys set up and file called \"ssh_ok\" exists in user's home."
    echo "  "
	echo "  $PROGNAME"
	echo "            -H IP"
	echo "            -u username"
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
		-u)
			USERNAME="$2"
			shift
			;;
		*)
			print_help
			exit $UNKNOWN
			;;
	esac
	shift
done

if [[ -n $HOSTNAME && -n $USERNAME ]]; then
	
	LOGIN=$(ssh -l $USERNAME $HOSTNAME "ls ssh_ok")
	echo $LOGIN

	if [[ -z $LOGIN ]]; then
		#statements
		echo "WARNING - SSH login failed"
		exit $WARNING
	else
		echo "OK - SSH login successful"
	fi
	
else 
	print_usage
	exit $UNKNOWN
fi
