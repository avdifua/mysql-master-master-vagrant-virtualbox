#!/bin/bash

install_requirements() {

  sudo setenforce 0
  sudo systemctl enable firewalld && sudo systemctl start firewalld
	sudo firewall-cmd --add-service=mysql --permanent && sudo firewall-cmd --reload
	sudo systemctl start firewalld
  sudo timedatectl set-timezone "Europe/Kiev"
#  sudo yum update -y
  sudo yum install wget yum-utils -y
  sudo wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
  sudo yum localinstall mysql57-community-release-el7-11.noarch.rpm -y
  sudo yum-config-manager --enable mysql57-community
  sudo yum install mysql-community-server -y
  sudo service mysqld start
}

disable_selinux() {

  sudo sed -i -e "s|SELINUX=enforcing|SELINUX=disabled|g" /etc/selinux/config
}

get_temporary_password() {

  string_with_passw=$(sudo cat /var/log/mysqld.log | grep "A temporary")
  temp_pass="${string_with_passw#*localhost: }"
}

setup_mysql() {

  sudo su
  root_db_pass="kk3iDhwFEZYtJW8=slave"
  user_db_pass="cFGc0ulFPkwPyyk="
  slave_pass="cFGc0ulFPkwPy!"
  echo -e "[client]\npassword=$temp_pass" >~/.my.cnf
  mysql -u root --connect-expired-password <<SQL_QUERY
SET PASSWORD = PASSWORD("$root_db_pass");
FLUSH PRIVILEGES;
CREATE DATABASE eschool CHARSET = utf8 COLLATE = utf8_unicode_ci;
CREATE USER 'eschool_user'@'%' IDENTIFIED BY "$user_db_pass";
GRANT ALL PRIVILEGES ON eschool.* TO 'eschool_user'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%' IDENTIFIED BY "cFGc0ulFPkwPy!";
FLUSH PRIVILEGES;
STOP SLAVE;
SQL_QUERY

mysql -u root -p --password="$root_db_pass" -e "CHANGE MASTER TO MASTER_HOST='$masterip1', MASTER_USER='slave', MASTER_PASSWORD='$slave_pass', MASTER_LOG_FILE='$master1_log', MASTER_LOG_POS=$master1_position;" 2>/dev/null
mysql -u root -p --password="$root_db_pass" -e "START SLAVE;" 2>/dev/null

}

get_master_status_internalip(){
  mysql -u root -p --password="$root_db_pass" -e "SHOW MASTER STATUS" > /vagrant/tmp2.txt 2>/dev/null
  master_status="$(</vagrant/tmp2.txt)"
  echo "$(echo $master_status | awk '{print $6}')" > /vagrant/tmp2.txt && echo "$(echo $master_status | awk '{print $7}')" >> /vagrant/tmp2.txt
  echo "$(hostname -I)" | awk '{print $2}' >> /vagrant/tmp2.txt
  echo "$slave_pass" >> /vagrant/tmp2.txt

}

edit_my_cnf(){

	FILE="/etc/my.cnf"

sudo cat <<_EOF >>$FILE
server-id=12
log-bin="mysql-bin"
binlog-do-db=eschool
replicate-do-db=eschool
relay-log="mysql-relay-log"
auto-increment-offset = 12
_EOF

  sudo systemctl restart mysqld

}

read_data_file(){
  DATA_FILE=$(</vagrant/tmp.txt)

  master1_log=$(echo $DATA_FILE | awk '{print $1}')
  master1_position=$(echo $DATA_FILE | awk '{print $2}')
  masterip1=$(echo $DATA_FILE | awk '{print $3}')
  slave_pass=$(echo $DATA_FILE | awk '{print $4}')
}

import_dump(){

  mysql -u root -p --password="$root_db_pass" eschool < /vagrant/fulldb08-10-2020_13-32.sql 2>/dev/null

}


disable_selinux
read_data_file
install_requirements
edit_my_cnf
get_temporary_password
setup_mysql
import_dump
get_master_status_internalip