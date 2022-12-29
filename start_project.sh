#!/bin/bash

if [ "$1" == "debug" ]; then
	debug=""
	echo "Debug on !"
else
	debug="> /dev/null"
	echo "Debug off: ./start_project.sh debug"
fi

echo "Start Terraform creation ..."

source /home/eductive09/openrc.sh
cd /home/eductive09/Linux_Project/terraform
eval "terraform apply --auto-approve $debug"

echo "Sleep 30s for servers to spawn ..."
sleep 30s

echo "Playing Ansible playbooks, take a cofee and relax :) ..."
eval "ansible-playbook /home/eductive09/Linux_Project/ansible/servers_config.yml -i /home/eductive09/Linux_Project/ansible/inventory.yml --ssh-common-args='-o StrictHostKeyChecking=no' $debug"

echo "All done !"

terraform output

echo -ne "Front IP Address : " && terraform show | tr '\n' ' ' | grep -oP 'front_ip = \[.*\]' | cut -d'[' -f2 | cut -d']' -f 1 | cut -d',' -f2 | cut -d '"' -f 2
