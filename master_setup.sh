#!/bin/bash

read_data_file(){
  DATA_FILE=$(</vagrant/tmp2.txt)

  master2_log=$(echo $DATA_FILE | awk '{print $1}')
  master2_position=$(echo $DATA_FILE | awk '{print $2}')
  masterip2=$(echo $DATA_FILE | awk '{print $3}')
  slave_pass=$(echo $DATA_FILE | awk '{print $4}')
}

setup_master1(){
  root_db_pass="kk3iDhwFEZYtJW8="

  mysql -u root -p --password="$root_db_pass" -e "STOP SLAVE;" 2>/dev/null
  mysql -u root -p --password="$root_db_pass" -e "CHANGE MASTER TO MASTER_HOST='$masterip2', MASTER_USER='slave', MASTER_PASSWORD='$slave_pass', MASTER_LOG_FILE='$master2_log', MASTER_LOG_POS=$master2_position;" 2>/dev/null
  mysql -u root -p --password="$root_db_pass" -e "START SLAVE;" 2>/dev/null

}

read_data_file
setup_master1