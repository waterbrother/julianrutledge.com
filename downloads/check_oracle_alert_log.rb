#!/usr/bin/ruby

#########################################################################
#									#
#	Author: 	Julian Rutledge, julian@julianrutledge.com	#
#	Date:		November 16, 2015				#
#	Version:	1.2						#
#	License:	GPLv3						#
#	Notes:		Nov 18, 2015 - added hash constant to create	#
#			ability to change logic 			#
#			Nov 20, 2015 - fixed notification bug and	#
#			added debugging output. bug as due to a false	#
#			0 being returned as the current log length	#
#			due to a faulty ssh connection. 		#
#									#
#########################################################################


#Define script constants
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

#FULLPATH=File.expand_path(File.dirname(__FILE__)) #unecessary
SCRIPTNAME=File.expand_path(__FILE__)
#regex matching the timestamp of the entry.
DATELINE=/^[A-Z]+[a-z]+[a-z]+\s+[A-Z]+[a-z]+[a-z]+\s+[0-3]+[0-9]+\s[0-2]+[0-9]+:+[0-5]+[0-9]+:+[0-5]+[0-9]+\s[1-3]+[0-9]+[0-9]+[0-9]$/
ALERT_CONDITIONS = {
#THIS IS WHERE THE MAGIC HAPPENS
#if you want to change the logic of the alert, here's where to do it
"fa"=>"( str =~ /ORA-/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"cv"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ and str !~ /voprvl1/) or ( str =~ /[C,c]orrupt/ )",
"m5sdcp"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ and str !~ /voprvl1/) or ( str =~ /[C,c]orrupt/ )",
"m5sjwp"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ and str !~ /voprvl1/) or ( str =~ /[C,c]orrupt/ )",
"m5dalsp"=>"( str =~ /ORA-/ and str !~ /ORA-00060/ and str !~ /ORA-20011/ and str !~ /ORA-29400/ and str !~ /ORA-29913/ and str !~ /voprvl1/) or ( str =~ /[C,c]orrupt/ )",
"m5ddotp"=>"( str =~ /ORA-/ and str !~ /ORA-00060/ and str !~ /voprvl1/) or ( str =~ /[C,c]orrupt/ )",
"m5acp"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"m5detp"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ and str !~ /voprvl1/) or ( str =~ /[C,c]orrupt/ )",
"m5dschp"=>"( str =~ /ORA-/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"m5nycp"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"m5scctp"=>"( str =~ /ORA-/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"m5swfwp"=>"( str =~ /ORA-/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"m5adpylp"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"m5txdotp"=>"( str =~ /ORA-/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"wconf"=>"( str =~ /ORA-/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )",
"iviewp"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ and str !~ /voprvl1/) or ( str =~ /[C,c]orrupt/ )",
"m5unicp"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ and str !~ /ORA-01555/) or ( str =~ /[C,c]orrupt/ )",
"oda"=>"( str =~ /ORA-/ and str !~ /ORA-1652/ and str !~ /ORA-00060/ ) or ( str =~ /[C,c]orrupt/ )"
}

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
	puts "-S: sets the path of the file used to remember the status of the monitored log file."
	puts "-L: sets the logic of the check against each log entry; selects from a hash of possible values."
	puts 
	puts "Usage:"
	puts "The first time the script is executed, it will create the statfile and return OK so that"
	puts "no previously existing conditions in the log create alerts. After this, the script will"
	puts "remember where it left off and alert on any new conditions that arise. After this, any"
	puts "errors found in the logs will trigger alerts. If there are no changes in the log file the"
	puts "next time the script is checked, the alert condition will be marked as resolved because only"
	puts "new log entries will be parsed for errors. SSH keys must be set up before this script can run."
	puts 
	puts "Example usage:"
	puts "check_oracle_alert_log.rb -H=host -U=user -F=/fullpath/to/remote/logfile -S=/path/to/local/satefile -L=fa"
	puts
end

def get_arg(str)
	arg = str.split("=")
	return arg[1]
end

def read_file(file)
	f = File.open("#{file}", "r")
	contents=f.read
	f.close
	return contents
end

def write_file(file, contents)
	f = File.open("#{file}", "w")
	f.write("#{contents}")
	f.close
end

def create_array(raw_data)
	#create a multi-dimensional array and add each line of log data to it
	log_entries = Array.new
	entry_count=-1
	raw_data.each do |line|
		if line =~ DATELINE
		#if the line is a time stamp, make a new array, add it as the first element, and 
		#add to our count of entries. because we count from zero, we start at -1 and add 
		#one right away - even if the log is checked between completed entries, the -1 
		#element in the array is the last element, and the last element in an empty array is
		#still the first element. this way, we start counting form zero, but a new array 
		#is created for each dateline found			
			entry_count += 1
			new_entry = Array.new
			new_entry[0] = line
			log_entries << new_entry
		elsif line !~ DATELINE and log_entries.length == 0
		#if the line is not a time stamp and it is the first entry in the raw data, create
		#a new array and add it to the log_entries array. this should only happen if the log
		#is checked while oracle is creating a log entry
			entry_count += 1
			new_entry = Array.new
			new_entry[0] = line
			log_entries << new_entry
		else
		#add the log entry to the current array in Log_entries
			log_entries[entry_count] << line
		end
	end
	return log_entries
end

def string_contains_errors?(str)
	contains_errors=nil
	if eval(ALERT_CONDITIONS[$logic])
		contains_errors	= true
	else
		contains_errors	= false
	end
	return contains_errors
end

def parse_data(log_array)
	#returns an array of arrays of failing log entries
	failing_entries = Array.new
	log_array.each do |entry|
		fails = nil
		entry.each do |line|
			if string_contains_errors?(line) == true
				fails = true
			end
		end
		if fails == true
			failing_entries << entry
		end
	end
	return failing_entries
end

def get_failures(array)
	#returns a string of failing log entries, removing newlines
	#for printing to nagios alert
	failcodes=String.new
	array.each do |a|
		a.each do |line|
			lineout = line.chomp + "        "
			failcodes << lineout
		end
	end
	return failcodes
end

def get_current_log_length
	log_length=`ssh -l #{$user} #{$hostname} "wc -l #{$filepath}"`
	return log_length.split(" ")[0]
end

def get_new_loginfo(log_diff)
	#get the raw log info. ruby automatically returns the value of the last line in a function. 
	`ssh -l #{$user} #{$hostname} "tail -n #{log_diff} #{$filepath}"`
end

def get_all_loginfo
	#get the raw log info. ruby automatically returns the value of the last line in a function. 
	`ssh -l #{$user} #{$hostname} "cat #{$filepath}"`
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
	elsif a=~ /-S=/
		$statfile=get_arg(a)
	elsif a=~ /-L=/
		$logic=get_arg(a)
	end
end

#main script
if defined? $hostname and defined? $user and defined? $filepath and defined? $statfile and defined? $logic
	#check to see if the statfile exists. if not, assume this is the first time the 
	#script has run. 
	#
	#Note: File.file? only returns true for files, but File.exist? returns true for directories 
	if File.file?($statfile)
		$FIRSTRUN = "false"
	else
		$FIRSTRUN = "true"
	end

	if ALERT_CONDITIONS.has_key?($logic) == false
		puts "Specified logic cannot be found."
		exit UNKNOWN
	end
		
	if $FIRSTRUN == "true"
		#use a loop to make sure we do not get a false zero. 
		log_length = 0
		until log_length.to_i > 0 do
			log_length = get_current_log_length
		end

		write_file($statfile, log_length)
		puts "first time script has run, # of entries: #{log_length}, status: OK."
		exit OK
	elsif $FIRSTRUN == "false"
		#use a loop to make sure we do not get a false zero. 
		current_log_length = 0
		until current_log_length.to_i > 0 do
			current_log_length = get_current_log_length
		end

		last_checked_log_length=read_file($statfile).to_i

		print "Last log count: #{last_checked_log_length.to_s}, Current log count: #{current_log_length}, "
		
		log_diff=current_log_length.to_i - last_checked_log_length
		if log_diff > 0
			#use a loop to make sure we actually get the log info
			raw_loginfo=""
			until raw_loginfo =~ DATELINE do
				raw_loginfo=get_new_loginfo(log_diff)
			end
			log_entries = create_array(raw_loginfo)
			failures=parse_data(log_entries)
			print "log has new entries. # of new lines: #{log_diff}, failures: #{failures.length}, "

			if failures.length > 0
				failing_entries=get_failures(failures)
				write_file($statfile, current_log_length)
				print "failing entries: #{failing_entries} \n"
				exit WARNING
			else
				write_file($statfile, current_log_length)
				print "status: OK \n"
				exit OK
			end
		elsif log_diff < 0
			#use a loop to make sure we actually get the log info
			raw_loginfo=""
			until raw_loginfo =~ DATELINE do
				raw_loginfo=get_all_loginfo
			end
			log_entries = create_array(raw_loginfo)
			failures=parse_data(log_entries)
			print "log has rotated. # of lines: #{current_log_length}, failures: #{failures.length}, "
			if failures.length > 0 and log_diff > 0
				failing_entries=get_failures(failures)
				write_file($statfile, current_log_length)
				print "failing entries: #{failing_entries} \n"
				exit WARNING
			else
				write_file($statfile, current_log_length)
				print "status: OK \n"
				exit OK
			end
		elsif log_diff == 0
			print "no log changes. \n"
			exit OK
		end
	end
else 
	print_help
	exit UNKNOWN
end
