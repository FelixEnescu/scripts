#!/bin/bash
#

# Script to install base components on servers
# 
# Requires:
#	qsol_keys_set
#
# Version 1.1
#
# 2013-01-29 FLX f@qsol.ro
#	- Redirected ntpdate to /dev/null
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

packets='bind-utils wget mc logrotate'
other_packets='mysql-server'

mysql=0

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

if which yum >/dev/null 2>&1; then
	echo "Using yum."
	install_cmd='yum install --assumeyes'
	local_install_cmd='yum localinstall --nogpgcheck --assumeyes '
elif which apt-get; then
	echo "Using apt-get. Debian not really tested - use on your own risk."
	install_cmd='apt-get install '
	local_install_cmd='dpkg --install '
else
	echo "yum or apt-get not found."
	exit 127
fi

#########################################
#
# Regular packages
#
for pkt in $packets; do
	if $install_cmd $pkt; then
		echo "$pkt ok."

	else 
		echo "$pkt failed."
		exit 127
	fi
done

#########################################
#
# Special installs
#

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

if which ntpdate >/dev/null 2>&1; then
	echo "ntp found."
else
	$install_cmd ntp

	if which ntpdate >/dev/null 2>&1; then
		echo "ntp installation ok."
		ntpdate pool.ntp.org
		echo "#!/bin/bash" > /etc/cron.daily/ntp
		echo "/usr/sbin/ntpdate pool.ntp.org >/dev/null" >> /etc/cron.daily/ntp
		chmod +x /etc/cron.daily/ntp
		/etc/cron.daily/ntp
		service crond restart
	else
		echo "ntp installation failed."
		exit 127
	fi
fi

if [ "$mysql" = "1" ] ; then
	$install_cmd mysql-server
	
	if [ -x "/usr/bin/mysqld_safe" ]; then
		echo "MySQL installation ok."
		chkconfig --levels 2345 mysqld on
		service mysqld start
		/usr/bin/mysql_secure_installation
		echo "Create logrotate script."
		cat > /etc/logrotate.d/mysql <<ENDOFMESSAGE
		
			/var/log/mysql/mysql_slow_queries.log
			/var/log/mysql/mysqld.err
			{
				missingok
				notifempty
				sharedscripts
				weekly
				compress
				rotate 10
				postrotate
					/usr/bin/mysqladmin flush-logs
				endscript
			}
			
			
ENDOFMESSAGE
		
	else
		echo "MySQL installation failed."
		exit 127
	fi
/usr/bin/mysqld_safe
fi

exit 0



