#!/bin/bash

#
# Check Jonar's web site
#
# Version 1.2
#
# 2012-12-16 FLX f@qsol.ro
#	- Modified to fully use parameters
#
# 2012-12-05 FLX f@qsol.ro
#	- Added option to update baseline
#
# 2012-12-4 FLX f@qsol.ro
#	- Started
#
#
#

#####################################################################
#
#	Global Configure section
#
#####################################################################

site='www.logictivity.com'

ftpuser=felixsydney
ftppassword=JonarAus2

working_dir='/root/felix'
sysadmin='felix.enescu@qwerty-sol.ro'

log_file_prefix="check.result"
md5_file_prefix="md5.baseline"

#####################################################################

function PRINT_USAGE(){
  echo "This script check a site for modifications :
  -c check md5sum
  -u update
  -h    prints out this help
You must at least specify check or update."
  exit 0
}

function LOG(){
	local msg="$1"
	echo `date +"%Y-%m-%d %H:%M:%S"` $msg >> $site.$log_file_prefix.$now
}

function EOJ(){
	local exit_code=$1
	LOG "Exiting"
	cat $site.$log_file_prefix.$now | mailx -s "$site integrity check" $sysadmin

	exit $exit_code
}

function UPDATE {
	LOG "Update started ..."

	mv $site.$md5_file_prefix $site.$md5_file_prefix.$now
	find . -path "./$site/*" -name "*.php"  -exec md5sum '{}' \; > $site.$md5_file_prefix

	LOG "Update finished." 
}

function CHECK {
	LOG "Check started ..."

	mv $site $site.$now
	LOG "  Start wget ..."
	wget --ftp-user=$ftpuser --ftp-password=$ftppassword --mirror -A php ftp://$site/
	LOG "  End wget."

	LOG "  Start md5sum ..."
	md5sum --check $site.$md5_file_prefix |grep -v OK | tee -a $site.$log_file_prefix.$now
	LOG "  End md5sum."
	
	LOG "Check finished."

}


#####################################################################
#
#	Main Program
#
#####################################################################

now=`date +"%Y-%m-%d.%H-%M"`

if ! which md5sum > /dev/null 2>&1; then
	LOG "Unable to find md5sum. Aborting."
	EOJ 1
fi

cd $working_dir/$site
if [ "`pwd`" != "$working_dir/$site" ]; then
	LOG "Unable to cd to $working_dir/$site."
	EOJ 2
fi

update=0
check=0
while true ; do
  getopts 'cuh' OPT 
  if [ "$OPT" = '?' ] ; then break; fi; 
  case "$OPT" in
    "c") check=1;;
    "u") update=1;;
    "h") PRINT_USAGE;;
  esac
done

if [ "$check" = '1' ] ; then
	LOG "Checking"
	CHECK
	EOJ 0
elif [ "$update" = '1' ] ; then
	LOG "Updating"
	UPDATE
	EOJ 0
else
	LOG "No command specified"
	EOJ 3
fi

# Shoudn't reach here
LOG "Unexpected finish."
EOJ 15
