#!/bin/bash

#################################################################################
#										#
#	Author:	Julian Rutledge							#
#	Date: 	2015-09-15							#
#	Version: 1.1								#
#	Notes:	Adapted from check_snmp_aix_disk.sh which was written by 	#
#		Helmet (blade2iron@gmail.com) on 2014-06-25.			#
#		Version 1.1: chaged code to include errpt contents in output	#
#										#
#	License: GPL - https://www.gnu.org/licenses/gpl.html			#
#										#
#################################################################################


OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

PROGNAME=`basename $0`

ATTEMPTS=1

print_usage() {
    echo "Check if errors found in error report."
    echo "  Will only trigger a warning, not a critical condition"
    echo "  This plugin assumes you have ssh keys set up on your remote host."
    echo "  "
	echo "  $PROGNAME"
	echo "            -H IP"
	echo "            -u user"
	echo " "
	echo "  example:"
	echo "  $PROGNAME -H 10.1.90.38 -u nagios"
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
			USER="$2"
			shift
			;;
		*)
			print_help
			exit $UNKNOWN
			;;
	esac
	shift
done

if [[ -n $USER && -n $HOSTNAME ]]; then
	
	ERRORS=$(ssh -l "$USER" "$HOSTNAME" "errpt -a")

	if [[ -n $ERRORS ]]; then
		message="WARNING - Errors found in error report:   "
		output=$message$ERRORS
		echo $output
		exit $WARNING
	else
		echo "OK - Error report is empty"
		exit $OK
	fi
	
else 
	print_usage
	exit $UNKNOWN
fi
