#!/bin/bash

#===================================================================================#
#                                                                                   #
#    Author:   Julian Rutledge, julian@julianrutledge.com                           #
#    Date:     October 13th, 2015                                                   #
#    License:  GPLv3                                                                #
#    Version:  1.1								    #
#    Notes: 2015-12-01: Added performance data to output                            #
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
	echo "In this case, the sql will check for the amount of m5 tables missing. If a value less"
	echo " than the specified warning or critical levels is returned, an alert will be triggered."
	echo ""
	echo "    Usage:"
	echo "        $NAME -d <database> -u <user> -p <password> -q <query_file> -w <number> -c <number>"
	echo ""
	echo "    Example:"
	echo "        $NAME -d base -u scott -p tiger -q archiver_query.txt -w 500 -c 600"
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

#define DB check function
check_db(){
	EXECUTE="echo -e '\004' | $SQLPLUS $USER/$PASSWD@$DB @$SQL"
	RESULT=`eval $EXECUTE`
	echo $RESULT
}

#in which we make the check
if [[ -n $DB && -n $USER && -n $PASSWD && -n $CRIT_LEVEL && -n $WARN_LEVEL ]]; then
	RESULT=`check_db`
	NUM_TABLES=`echo $RESULT | awk '{print $3}'`
	#echo $RESULT
	#echo $NUM_TABLES
	if [[ $RESULT =~ "ERROR" ]]; then 
		RESULT=`echo $RESULT | cut -d ";" -f 1`
		echo "WARNING - $RESULT | tables=0"
		exit $WARNING
	elif [[ $RESULT =~ "invalid" ]]; then 
		echo "WARNING - Query status: $RESULT | tables=0"
		exit $WARNING
	elif [[ -z $RESULT ]]; then
		echo "WARNING - Empty string returned | tables=0"
		exit $WARNING
	elif [[ $NUM_TABLES -le $CRIT_LEVEL ]]; then
		echo "CRITICAL - $NUM_TABLES tables | tables=$NUM_TABLES"
		exit $CRITICAL
	elif [[ $NUM_TABLES -le $WARN_LEVEL ]]; then 
		echo "WARNING - $NUM_TABLES tables | tables=$NUM_TABLES"
		exit $WARNING
	elif [[ $NUM_TABLES -gt $CRIT_LEVEL && $NUM_TABLES -gt $WARN_LEVEL ]]; then
		echo "OK - $NUM_TABLES tables | tables=$NUM_TABLES"
		exit $OK
	else
		echo "UNKNOWN - Could not get archiver status: $RESULT | tables=0"
		exit $UNKNOWN
	fi
else
	print_help
	exit $UNKOWN
fi

