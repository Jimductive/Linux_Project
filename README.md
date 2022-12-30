# Linux Project
## _Deploy instances:_
To start the project automatically (**No information** or in **Debug mode**):

```
bash /home/eductive09/Linux_Project/start_project.sh
bash /home/eductive09/Linux_Project/start_project.sh debug
```

To start the project manually
```
bash /home/eductive09/openrc.sh

cd /home/eductive09/Linux_Project/terraform
terraform apply --auto-approve

export DB_HOST=$(terraform output -raw cluster_uri | cut -d@ -f2 | cut -d/ -f1)
export DB_PASSWORD=$(terraform output -raw user_password)

cd /home/eductive09/Linux_Project/ansible
ansible-playbook servers_config.yml -i inventory.yml --extra-vars "DB_PASSWORD=$DB_PASSWORD DB_HOST=$DB_HOST" --ssh-common-args='-o StrictHostKeyChecking=no'
```

**To use the database for Wordpress don't forget to export the variables**

## _Project information:_

You will find 3 folders in this repository:
| Folder | Content |
| ------ | ------ |
| ansible | All Ansible playbooks to setup instances |
| templates | Terraform templates for Ansible use  |
| terraform | All Terraform configuration to start instances |
