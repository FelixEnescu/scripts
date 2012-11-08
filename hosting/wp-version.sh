#!/bin/bash

# Get Wordpress version for shared hosting accounts

cd /home

home_dirs=`ls -d */ | grep -v virtfs`
for acc in $home_dirs; do
	if [ -d "/home/$acc/public_html/wp-content/themes/" ]; then
		version=`grep wp_version /home/$acc/public_html/wp-includes/version.php | grep -v "@global"`
		echo "$acc WP: $version"

	fi
done

