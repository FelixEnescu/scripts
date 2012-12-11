#!/bin/bash

#
# Check Jonar's web site
#
# Version 1.1
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

working_dir='/root/felix'
site='www.logictivity.com'
sysadmin='felix.enescu@qwerty-sol.ro'

ftpuser=felixsydney
ftppassword=JonarAus2

#####################################################################

function PRINT_USAGE(){
  echo "This script check a site for modifications :
  -c check md5sum
  -u update
  -t HOURS  maximal age in hours for the latest backup before a warning is issued
  -T HOURS  maximal age in hours for the latest backup before a critical alert is issued
  -s KBYTES maximal size in kilo bytes for the latest backup before a warning is issued
  -S KBYTES maximal size in kilo bytes for the latest backup before a critical alert is issued
  -h    prints out this help
You must at least specify a directory and a minimal size or a minimal age."
  exit 0
}

function EOJ(){
	echo `date +"%Y-%m-%d %H:%M:%S"` "Exiting ..." >> check.result.$now
	cat check.result.$now | mailx -s "$site integrity check" $sysadmin

	exit 0
}

function UPDATE {
	echo `date +"%Y-%m-%d %H:%M:%S"` "Update started ..." >> check.result.$now

	mv $site.md5.baseline $site.md5.baseline.$now
	find . -path './www.logictivity.com/*' -name "*.php"  -exec md5sum '{}' \; > $site.md5.baseline

	echo `date +"%Y-%m-%d %H:%M:%S"` "Update finished ..." >> check.result.$now
}

function CHECK {
	echo `date +"%Y-%m-%d %H:%M:%S"` "Check started ..." >> check.result.$now

	mv $site $ite.$now
	echo `date +"%Y-%m-%d %H:%M:%S"` 'Start wget ...' >> check.result.$now
	wget --ftp-user=$ftpuser --ftp-password=$ftppassword --mirror -A php ftp://$site/
	echo `date +"%Y-%m-%d %H:%M:%S"` 'End wget ...' >> check.result.$now

	echo `date +"%Y-%m-%d %H:%M:%S"` 'Start md5sum ...' >> check.result.$now
	md5sum --check $site.md5.baseline |grep -v OK | tee -a check.result.$now
	echo `date +"%Y-%m-%d %H:%M:%S"` 'End md5sum ...' >> check.result.$now
	
	echo `date +"%Y-%m-%d %H:%M:%S"` "Check finished ..." >> check.result.$now

}


#####################################################################
#
#	Main Program
#
#####################################################################

now=`date +"%Y-%m-%d.%H-%M"`

cd $working_dir/$site
if [ "`pwd`" != "$working_dir/$site" ]; then
	echo `date +"%Y-%m-%d %H:%M:%S"` "Unable to cd to $working_dir/$site ..." >> check.result.$now
	EOJ
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
	echo `date +"%Y-%m-%d %H:%M:%S"` "Checking ..." >> check.result.$now
	CHECK
	EOJ
elif [ "$update" = '1' ] ; then
	echo `date +"%Y-%m-%d %H:%M:%S"` "Updating ..." >> check.result.$now
	UPDATE
	EOJ
else
	echo `date +"%Y-%m-%d %H:%M:%S"` "No command specified ..." >> check.result.$now
	EOJ
fi

echo `date +"%Y-%m-%d %H:%M:%S"` "Finished ..." >> check.result.$now
EOJ
