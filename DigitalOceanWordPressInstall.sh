#!/bin/bash
#Disabling SElinux

yum install wget -y
yum install lsof -y

sudo setenforce 0
cp -arp /etc/selinux/config  /etc/selinux/config.bak
sed -i '07 s/^/#/' /etc/selinux/config
echo "SELINUX=disabled" >> /etc/selinux/config
sestatus

#Install MySQL 5.7 service
cd /home/centos/
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum install mysql-server -y


#Install PHP and HTTPD service
yum install epel-release -y
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum install php72w  php72w-pdo php72w-mcrypt php72w-mbstring php72w-mysqlnd php72w-curl php72w-intl php72w-cli  php72w-fpm php72w-opcache  httpd24-devel httpd-tools httpd -y

#Make HTTPD and MySQL service to start on boot.
chkconfig httpd on
chkconfig mysqld on

#Start HTTPD and MySQL service
service httpd start
service mysqld start

#Set up MySQL root password.

newpass=`openssl rand -hex 8`
mysqladmin -u root password $newpass
echo $newpass

#Setup new database and logins for Wordpress site.
DBNAME=db
DBUSER=user
PASS=`openssl rand -base64 12`
NEWDBNAME=wordpress$DBNAME
echo $NEWDBNAME
NEWDBUSER=wordpress$DBUSER

mysql -u root -p$newpass -e "CREATE DATABASE ${NEWDBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -u root -p$newpass -e "CREATE USER '${NEWDBUSER}'@'localhost' IDENTIFIED BY '${PASS}';"
mysql -u root -p$newpass -e "GRANT ALL PRIVILEGES ON ${NEWDBNAME}.* TO '${NEWDBUSER}'@'localhost';"
mysql -u root -p$newpass -e "FLUSH PRIVILEGES;"
touch /home/centos/dblogin.txt
echo dbname=$NEWDBNAME > /home/centos/dblogin.txt
echo dbusername=$NEWDBUSER >> /home/centos/dblogin.txt
echo dbpassword=$PASS >> /home/centos/dblogin.txt
echo $PASS
echo [client] > /root/.my.cnf
echo user=root >> /root/.my.cnf
echo password="\"$newpass"\" >> /root/.my.cnf


#Install zip and unzip commands
yum install zip unzip -y
cd /var/www/html
wget https://wordpress.org/latest.zip
unzip latest.zip
cp -arp wordpress/wp-config-sample.php wordpress/wp-config-sample.bak
mv wordpress/wp-config-sample.php wordpress/wp-config.php
sed -i "s/database_name_here/$NEWDBNAME/g" wordpress/wp-config.php
sed -i "s/username_here/$NEWDBUSER/g" wordpress/wp-config.php
sed -i "s/password_here/$PASS/g" wordpress/wp-config.php
mv wordpress/* .
rm -rf wordpress
chown centos:apache /var/www/html -R
chmod 2775 /var/www/html -R
rm -f latest.zip
rm -f /home/centos/mysql-community-release-el7-5.noarch.rpm

