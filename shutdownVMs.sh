#!/usr/bin/env bash

NOT_HOST=""
REBOOT=""

usage() {
	echo "./$(basename "$0")"
	echo "./$(basename "$0") -n (WON'T SHUTDOWN PROXMOX)"
	echo "./$(basename "$0") -r (REBOOT PROXMOX)"
	exit 0
}


while getopts ":hnr" opt; do
	case "${opt}" in 
		h)
		    usage
		    ;;
	    	n)
		    NOT_HOST="1"
		    ;;
	    	r)
		    REBOOT="1"
		    ;;
		*)
		    usage
		    ;;
	esac
done


VM_LIST=$(qm list | grep running)

IFS=$'\n'

for vm_line in $VM_LIST; do
	vm_id=$(echo $vm_line | awk '{print $1}')
	vm_name=$(echo $vm_line | awk '{print $2}')
	echo "Shutting down $vm_name [$vm_id]"
	qm shutdown $vm_id --timeout=120 &
done

wait

echo -e "\n\nWaiting for VMs to gracefully shutdown...\n\n"

for vm_line in $VM_LIST; do
	vm_id=$(echo $vm_line | awk '{print $1}')
        vm_name=$(echo $vm_line | awk '{print $2}')
	qm wait $vm_id --timeout=60
	RC=$?
	if [[ "$RC" == 0 ]]; then
		echo "$vm_name successfully shutdown"
	else
		echo "$vm_name didn't shutdown normally... force stopping"
		qm stop $vm_id
	fi
done

if [[ -n "$REBOOT" ]]; then
	shutdown now
elif [[ -z "$NOT_HOST" ]]; then
	shutdown -r now
fi

