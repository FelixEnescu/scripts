#!/bin/sh

srv_list='amber catena escortguide gray seomonitor-mysql webmagnat bursa elefant getadeal groupall red seomonitor-www yellow'
bckp_list='daily weekly monthly'

base_dir='/volume1'
cpanel='cpbackup'

cd $base_dir

for srv in $srv_list; do
  if [ -d $base_dir/$srv/$cpanel ] ; then
		echo $base_dir/$srv/$cpanel
		for bck in $bckp_list; do
			dir_list=`ls -d $base_dir/$srv/$cpanel/$bck/*.[0123456789]`
			for dir in $dir_list; do
				echo $dir
				rm -rf $dir
			done
		done
	fi
done



