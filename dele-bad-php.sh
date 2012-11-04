#!/bin/bash

# Search and delete bad files 
bad_str='eval|gzinflate|str_rot13|base64_decode'


prefixes="public_html/wp-content/plugins public_html/docs/wp-content/plugins"
plugins="wp-pagenavi akismet"
to_del="admin.php mailer.php" 
#askimet.php"

#act='ls -l'
act='rm -rfv'

cd /home

home_dirs=`ls -d */ | grep -v virtfs`
for acc in $home_dirs; do
	#echo rm -f "/home/$acc/public_html/ow.php"
	if [ -f "/home/$acc/public_html/ow.php" ]; then
		echo "Infected:" `ls -l "/home/$acc/public_html/ow.php"`
		$act "/home/$acc/public_html/ow.php"
	fi
	if [ -d "/home/$acc/public_html/1" ]; then
		echo "Infected:" `ls -l "/home/$acc/public_html/1"`
		$act "/home/$acc/public_html/1"
	fi
	if [ -d "/home/$acc/public_html/2" ]; then
		echo "Infected:" `ls -l "/home/$acc/public_html/2"`
		$act "/home/$acc/public_html/2"
	fi
	for prefix in $prefixes; do
		for plug in $plugins; do
			if [ -d "/home/$acc/$prefix/$plug" ]; then
				#echo rm -f "/home/$acc/public_html/$plug/$plug.php"
				if [ -f "/home/$acc/$prefix/$plug/$plug.php" ]; then
					if grep -H -o -E "$bad_str" "/home/$acc/$prefix/$plug/$plug.php"; then
						echo "Infected:" `ls -l "/home/$acc/$prefix/$plug/$plug.php"`
						$act "/home/$acc/$prefix/$plug/$plug.php"
					fi
				fi
				for file in $to_del; do
					if [ -f "/home/$acc/$prefix/$plug/$file" ]; then
						if grep -H -o -E "$bad_str" "/home/$acc/$prefix/$plug/$file"; then
							echo "Infected:" `ls -l "/home/$acc/$prefix/$plug/$file"`
							$act "/home/$acc/$prefix/$plug/$file"
						fi
					fi
				done 
			fi
		done	# all plugins	
	done	# all prefixes
done	# all accounts

