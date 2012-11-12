#!/bin/bash
#

# Script to install base components on servers
#
# Version 1.0
#
# 2012-11-12 FLX f@qsol.ro
#	- Started
#	- Added ntp
#


#####################################################################
#
#	Global Configure section
#
#####################################################################

working_dir='/root/qsol'


#####################################################################


WGET='wget --no-verbose '

#####################################################################

if [ ! -d /root/qsol ]; then
	mkdir /root/qsol
fi
cd /root/qsol


crt_dir=`pwd`
if [ "$crt_dir" != "$working_dir" ] ; then
	echo "wrong working dir $crt_dir"
	exit 127
fi

if which yum; then
	echo "Using yum."
	install_cmd='yum install --assumeyes '
	local_install_cmd='yum localinstall --nogpgcheck --assumeyes '
elif which apt-get; then
	echo "Using apt-get. Debian not really tested - use on your own risk."
	install_cmd='apt-get install '
	local_install_cmd='dpkg --install '
else
	echo "yum or apt-get not found."
	exit 127
fi

if which wget ; then
	echo "wget found."
else
	$install_cmd wget

	if which wget ; then
		echo "wget installation ok."
	else
		echo "wget installation failed."
		exit 127
	fi
fi

if [ -x "/usr/sbin/crond" ]; then
	echo "crond found."
else
	$install_cmd cronie
	$install_cmd crontabs
	if [ -x "/usr/sbin/crond" ]; then
		echo "cronie installation ok."
		service crond restart
	else
		echo "cronie installation failed."
		exit 127
	fi
fi

if which ntpdate ; then
	echo "ntp found."
else
	$install_cmd ntp

	if which ntpdate ; then
		echo "ntp installation ok."
		ntpdate pool.ntp.org
		echo "#!/bin/bash" > /etc/cron.daily/ntp
		echo "/usr/sbin/ntpdate pool.ntp.org" >> /etc/cron.daily/ntp
		chmod +x /etc/cron.daily/ntp
		/etc/cron.daily/ntp
		service crond restart
	else
		echo "ntp installation failed."
		exit 127
	fi
fi


exit 0



