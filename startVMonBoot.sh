#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONF_FILES="/etc/pve/qemu-server"

ACTION="$1"
DISABLED_FILE="${SCRIPT_DIR}/onboot-vms-disabled.txt"


input_request(){
	while true; do
	    read -p "$1 " yn
	    case $yn in
	        [Yy]* ) break;;
	        [Nn]* ) echo "Aborting..."; exit 1;;
	        * ) echo "Please answer yes or no.";;
	    esac
	done
}


if [[ "$ACTION" == "disable" ]]; then
	if [[ -f $DISABLED_FILE ]]; then
		input_request "$DISABLED_FILE already exists! Overwrite?"
		echo rm $DISABLED_FILE
		rm $DISABLED_FILE
	fi

	touch $DISABLED_FILE
	for vmID in $(ls ${CONF_FILES}/*.conf); do
		vmFile="${vmID}"
		cat $vmFile | grep -q 'onboot: 1'
		if [[ "$?" == "0" ]]; then
			echo "Disabling start on boot for $vmFile"
			sed -i '/onboot: 1/d' $vmFile
			echo $vmFile >> $DISABLED_FILE
		fi
	done
elif [[ "$ACTION" == "enable" ]]; then
	for vmFile in $(cat $DISABLED_FILE); do
		echo "re-enabling start at boot for $vmFile"
		echo 'onboot: 1' >> $vmFile
	done
	rm $DISABLED_FILE
else
	echo "Invalid action '$ACTION'"
	exit 1
fi
	
#onboot: 1
