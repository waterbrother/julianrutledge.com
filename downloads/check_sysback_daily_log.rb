#!/usr/bin/ruby

#########################################################################
#									#
#	Author: 	Julian Rutledge, julian@julianrutledge.com	#
#	Date:		November 23, 2015				#
#	Version:	1.0						#
#	License:	GPLv3						#
#	Notes:								#
#						 			#
#									#
#########################################################################


#Define script constants
OK=0
WARNING=1
CRITICAL=2 #not used here
UNKNOWN=3

#FULLPATH=File.expand_path(File.dirname(__FILE__)) #unecessary
SCRIPTNAME=File.expand_path(__FILE__)
DATELINE=/[A-Z]+[a-z]+[a-z]+\s+[A-Z]+[a-z]+[a-z]+\s+[0-3]+[0-9]+\s[0-2]+[0-9]+:+[0-5]+[0-9]+:+[0-5]+[0-9]+\s[A-Z][A-Z][A-Z]+\s[1-3]+[0-9]+[0-9]+[0-9]/
ERRSTR=/TCP\/IP\sconnection\sfailure/
#ERRSTR=/error/

#Define functions
def print_help
	puts 
	#puts "#{FULLPATH}/#{SCRIPTNAME}"
	puts "#{SCRIPTNAME}"
	puts 
	puts "Arguments:"
	puts "-h, --help: calls this help function."
	puts "-H: sets the name of the host to which the script will connect."
	puts "-U: sets the user login needed to connect to the host."
	puts "-F: sets the path of the log file on the host to be monitored."
	puts 
	puts "Usage:"
	puts "This script is written to be executed once daily and parse all log entries in the log file"
	puts "for errors. It is assumed that the file is new every time the script is executed, so there is"
	puts "no logic to accommodate for changes in the log over time. SSH keys must be set up before"
	puts "this script can run."
	puts 
	puts "Example usage:"
	puts "#{__FILE__} -H=host -U=user -F=/fullpath/to/remote/logfile"
	puts
end

def get_arg(str)
	#returns the value passed with an argument to the script. ruby automatically returns the value of the last line in a function. 
	str.split("=")[1]
end

def get_all_loginfo
	#get the raw log info. ruby automatically returns the value of the last line in a function. 
	`ssh -l #{$user} #{$hostname} "cat #{$filepath}"`
end

def logstr(log)
	str = ""
	log.each { |line| str << line.chomp }
	return str
end

#Parse arguments
ARGV.each do |a|
	if a =~ /--help/
		print_help
		exit UNKNOWN
	elsif a=~ /-h/
		print_help
		exit UNKNOWN
	elsif a=~ /-H=/
		$hostname=get_arg(a)
	elsif a=~ /-U=/
		$user=get_arg(a)
	elsif a=~ /-F=/
		$filepath=get_arg(a)
	end
end

#main script
if defined? $hostname and defined? $user and defined? $filepath
	#use a loop to make sure we get info despite any flaky ssh connection
	loginfo = ""
	until loginfo =~ DATELINE
		loginfo = get_all_loginfo
	end

	logline = logstr(loginfo)
	if loginfo =~ ERRSTR
		puts "WARNING: error in log data: #{logline}"
		exit WARNING
	else
		puts "OK: no errors found in log data"
		exit OK
	end
else 
	print_help
	exit UNKNOWN
end
