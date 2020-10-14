#!/bin/bash

install_requirements() {

	sudo setenforce 0
	sudo systemctl enable firewalld && sudo systemctl start firewalld
	sudo firewall-cmd --add-service=mysql --permanent && sudo firewall-cmd --reload
	sudo systemctl start firewalld
	sudo timedatectl set-timezone "Europe/Kiev"
#	sudo yum update -y
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
root_db_pass="kk3iDhwFEZYtJW8="
user_db_pass="cFGc0ulFPkwPyyk="
slave_pass="cFGc0ulFPkwPy!"
echo -e "[client]\npassword=$temp_pass" > ~/.my.cnf
mysql -u root --connect-expired-password <<SQL_QUERY
SET PASSWORD = PASSWORD("$root_db_pass");
FLUSH PRIVILEGES;
CREATE DATABASE eschool CHARSET = utf8 COLLATE = utf8_unicode_ci;
CREATE USER 'eschool_user'@'%' IDENTIFIED BY "$user_db_pass";
GRANT ALL PRIVILEGES ON eschool.* TO 'eschool_user'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%' IDENTIFIED BY "$slave_pass";
FLUSH PRIVILEGES;
SQL_QUERY
}

get_master_status_internalip(){
  mysql -u root -p --password="$root_db_pass" -e "SHOW MASTER STATUS" > /vagrant/tmp.txt 2>/dev/null
  master_status="$(</vagrant/tmp.txt)"
  echo "$(echo $master_status | awk '{print $6}')" > /vagrant/tmp.txt && echo "$(echo $master_status | awk '{print $7}')" >> /vagrant/tmp.txt
  echo "$(hostname -I)" | awk '{print $2}' >> /vagrant/tmp.txt
  echo "$slave_pass" >> /vagrant/tmp.txt

}

edit_my_cnf(){

	FILE="/etc/my.cnf"

sudo cat <<_EOF >>$FILE
server-id=11
log-bin="mysql-bin"
binlog-do-db=eschool
replicate-do-db=eschool
relay-log="mysql-relay-log"
auto-increment-offset = 11
_EOF

  sudo systemctl restart mysqld

}

import_dump(){

  mysql -u root -p --password="$root_db_pass" eschool < /vagrant/fulldb08-10-2020_13-32.sql 2>/dev/null

}

disable_selinux
install_requirements
edit_my_cnf
get_temporary_password
setup_mysql
import_dump
get_master_status_internalip