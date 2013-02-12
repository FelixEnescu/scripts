#!/bin/bash



doms[1]='qsm.ro'
class[1]='89.32.124'
start_ips[1]=2
end_ips[1]=39

doms[2]='qsm-marketing.info'
class[2]='37.153.136'
start_ips[2]=2
end_ips[2]=250

doms[3]='diverseafaceri.ro'
class[3]='89.36.199'
start_ips[3]=2
end_ips[3]=250





icinga_cfg_dir='/usr/local/icinga/etc/conf.d'



rm -f $0


for i in $(seq 1 1 ${#doms[@]}) ; do
	echo "Process domain ${doms[$i]}"
		

	#
	# Create domain config file
	#
	domain="${doms[$i]}"	
	cat > $icinga_cfg_dir/${domain}.cfg <<-ENDOFMESSAGE

	define hostgroup{
	    hostgroup_name		${domain}
	    alias				Domain ${domain}
	    }

	define host{
	    use					sender
	    host_name			${domain}
	    hostgroups			+${domain}
	    }

	define service{
	    use					rbl-dom
	    host_name			${domain}
	    }

	ENDOFMESSAGE

	


	#
	# Create IP RBL config file header
	#
	ip_class="${class[$i]}"
	start_ip=${start_ips[$i]}
	end_ip=${end_ips[$i]}
	
	cat > $icinga_cfg_dir/${domain}.${ip_class}.cfg <<-ENDOFMESSAGE

	define hostgroup{
	    hostgroup_name          IP_Class_${ip_class}.0
	    alias                   IP Class ${ip_class}.0
	    }

	define service{
	    use                 rbl-ip
	    hostgroup_name      IP_Class_${ip_class}.0
	    }
		
	define service{
	    use                 senderscore
	    hostgroup_name      IP_Class_${ip_class}.0
	    }

	ENDOFMESSAGE

	#
	# Create IP RBL config file all IPs
	#
	for i in $(seq $start_ip 1 $end_ip) ; do
	   echo "    Sender $i"
	  
		cat >> $icinga_cfg_dir/${domain}.${ip_class}.cfg <<-ENDOFMESSAGE

		define host{
			use                 sender
			hostgroups          +IP_Class_${ip_class}.0,${domain}
			host_name           ${ip_class}.${i}
	    }
		ENDOFMESSAGE

	done	# for each IP in domain
	
done	# for each domain

exit





