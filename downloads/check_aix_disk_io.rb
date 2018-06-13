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
CRITICAL=2
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
	puts "-D: sets the disk on the host to be monitored."
	puts "-w: sets the warning levels for blocks read and blocks writen, respectively"
	puts "-c: sets the crtical levels for blocks read and blocks writen, respectively."
	puts 
	puts "Usage:"
	puts "Provides IOPS for the provided disk. Depends on ssh keys being set up, and iostat on the monitored server. "
	puts 
	puts "Example usage:"
	puts "#{__FILE__} -H=host -U=user -D=hdisk3 -w=800,7000 -c=1000,8000"
	puts
end

def get_arg(str)
	#returns the value passed with an argument to the script. ruby automatically returns the value of the last line in a function. 
	str.split("=")[1]
end

def get_disk_bread
	#gets the current stat of blocks read per second. 
	#ruby automatically returns the value of the last line in a function. 
	`ssh -l #{$user} #{$hostname} "iostat -D #{$disk} | head -5 | tail -1"`.split(" ")[-2]
end

def get_disk_bwrtn
	#gets the current stat of blocks written per sercond. 
	#ruby automatically returns the value of the last line in a function. 
	`ssh -l #{$user} #{$hostname} "iostat -D #{$disk} | head -5 | tail -1"`.split(" ")[-1]
end

def get_alert_levels(str)
	#return an array from the string given of the bread and bwrtn acceptable levels
	str.split(",")
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
	elsif a=~ /-D=/
		$disk=get_arg(a)
	elsif a=~ /-w=/
		$warn_levels=get_arg(a)
	elsif a=~ /-c=/
		$crit_levels=get_arg(a)
	end
end

def to_bytes(str)
	#remove suffix and convert to bytes - man page of AIX iostat says that these are incremented by 1000, NOT 1024. 
	if str=~ /K/
		str = str.chop.to_f * 1_000
		str = str.to_s
	elsif str =~ /M/
		str = str.chop.to_f * 1_000_000
		str = str.to_s
	elsif str =~ /G/
		str = bwrtn.chop.to_f * 1_000_000_000
		str = bwrtn.to_s
	elsif str =~ /T/
		str = bwrtn.chop.to_f * 1_000_000_000_000
		str = bwrtn.to_s
	end

	return str
end

#main script
if defined? $hostname and defined? $user and defined? $disk and defined? $warn_levels and defined? $crit_levels
	#use a loop to make sure we get info despite any flaky ssh connection
	bread = ""
	until bread.length > 0
		bread = get_disk_bread
	end

	#use a loop to make sure we get info despite any flaky ssh connection
	bwrtn = ""
	until bwrtn.length >0
		bwrtn = get_disk_bwrtn
	end
	
	bread = to_bytes(bread)
	bwrtn = to_bytes(bwrtn)

	#puts "bytes read per second: " + bread
	#puts "bytes written per second: " + bwrtn
	
	#process our input
	if bread.to_f >= get_alert_levels($crit_levels)[0].to_f or bwrtn.to_f >= get_alert_levels($crit_levels)[1].to_f
		puts "CRITICAL: bytes read/sec: #{bread}, bytes wrtn/sec: #{bwrtn} | bread_psec=#{bread} bwrtn_psec=#{bwrtn}"
		exit CRITICAL
	elsif bread.to_f >= get_alert_levels($warn_levels)[0].to_f or bwrtn.to_f >= get_alert_levels($warn_levels)[1].to_f
		puts "WARNING: bytes read/sec: #{bread}, bytes wrtn/sec: #{bwrtn} | bread_psec=#{bread} bwrtn_psec=#{bwrtn}"
		exit WARNING
	elsif bread.to_f < get_alert_levels($warn_levels)[0].to_f and bwrtn.to_f < get_alert_levels($warn_levels)[1].to_f
		puts "OK: bytes read/sec: #{bread}, bytes wrtn/sec: #{bwrtn} | bread_psec=#{bread} bwrtn_psec=#{bwrtn}"
		exit OK
	else 
		puts "UNKOWN | bread_psec=0 bwrtn_psec=0"
		exit UNKNOWN
	end
else 
	print_help
	exit UNKNOWN
end
