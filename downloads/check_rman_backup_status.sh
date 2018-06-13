#!/bin/bash

#===================================================================================#
#                                                                                   #
#    Author:   Julian Rutledge, julian@julianrutledge.com                           #
#    Date:     October 13th, 2015                                                    #
#    License:  GPLv3                                                                #
#    Notes:                                                                         #
#                                                                                   #
#===================================================================================#

#define exit codes as constants
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3


#define constants and help function
SQLPLUS="/usr/lib/oracle/12.1/client64/bin/sqlplus -S"
#this stupid file needs to be in a place that the apache user can read. what a pain, Nagios!
#export TNS_ADMIN="/ora/" #tnsnames.ora

#this needs to be defined before the arguments are parsed because it may be called there
print_help(){
	FULLNAME=`readlink -e $0`
	NAME=`basename $0`
	echo "$FULLNAME"
	echo "Executes a SQL statement against an Oracle Database and alerts on expected result."
	echo "In this case, the sql will check for the amount of RMAN backups in hte last 26 hours."
	echo "If a value more than zero is returned, an alert will not be triggered."
	echo ""
	echo "    Usage:"
	echo "        $NAME -d <database> -u <user> -p <password> -q <query_file>"
	echo ""
	echo "    Example:"
	echo "        $NAME -d base -u scott -p tiger -q archiver_query.txt"
}


while [ -n "$1" ]; do
	case "$1" in
		--help)
			print_help
			exit $UNKNOWN
			;;
		-h)
			print_help
			exit $UNKNOWN
			;;
		-d)
			DB="$2"
			shift
			;;
		-u)
			#possible security risk:
			#this information is passed in plain text
			#and could be seen by any user with the ability to
			#run `ps -e`
			USER="$2"
			shift
			;;
		-p)
			#possible security risk:
			#this information is passed in plain text
			#and could be seen by any user with the ability to
			#run `ps -e`
			PASSWD="$2"
			shift
			;;
		-q)
			SQL="$2"
			shift
			;;
		*)
			print_help
			exit $UNKNOWN
			;;
	esac
	shift
done

#define DB check function
check_db(){
	EXECUTE="echo -e '\004' | $SQLPLUS $USER/'$PASSWD'@$DB @$SQL"
	RESULT=`eval $EXECUTE`
	echo $RESULT
}

#in which we make the check
if [[ -n $DB && -n $USER && -n $PASSWD ]]; then
	RESULT=`check_db`
	NUM_BKUPS=`echo $RESULT | awk '{print $3}'`
	#echo $RESULT
	#echo $NUM_BKUPS
	if [[ $RESULT =~ "ERROR" ]]; then 
		RESULT=`echo $RESULT | cut -d ";" -f 1`
		echo "WARNING - $RESULT"
		exit $WARNING
	elif [[ $RESULT =~ "invalid" ]]; then 
		echo "WARNING - Query status: $RESULT"
		exit $WARNING
	elif [[ -z $RESULT ]]; then
		echo "WARNING - Empty string returned"
		exit $WARNING
	elif [[ $NUM_BKUPS -eq 0 ]]; then
		echo "CRITICAL - RMAN Backup not running"
		exit $CRITICAL
	elif [[ $NUM_BKUPS -gt 0 ]]; then
		echo "OK - $NUM_BKUPS backups running"
		exit $OK
	else
		echo "UNKNOWN - Could not get archiver status: $RESULT"
		exit $UNKNOWN
	fi
else
	print_help
	exit $UNKOWN
fi

