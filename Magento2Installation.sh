#!/bin/bash
#Disabling SElinux

yum install wget bind-utils -y
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
rm -f mysql-community-release-el7-5.noarch.rpm
yum install mysql-server -y


#Install PHP and HTTPD service

yum install epel-release -y
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum install php72w  php72w-pdo php72w-bcmath php72w-mbstring php72w-mysqlnd php72w-curl php72w-intl php72w-cli  php72w-fpm php72w-opcache php72w-bcmath php72w-gd php72w-dom php72w-soap php72w-xsl httpd24-devel httpd-tools httpd -y
cp -arp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
sed -i '151s/None/All/g'  /etc/httpd/conf/httpd.conf

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

#Setup new database and logins for Magento site.

DBNAME=db
DBUSER=user
PASS=`openssl rand -base64 12`
NEWDBNAME=magento$DBNAME
echo $NEWDBNAME
NEWDBUSER=magento$DBUSER

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

#Installing Composer command

cd /tmp
sudo curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#Install zip and unzip commands

yum install zip unzip git -y

#Downloading Magento2 files and placing it in /var/www/html Document Root

mv /var/www/html /var/www/html.bak
cd /var/www
git clone https://github.com/magento/magento2.git
mv magento2 /var/www/html
cd /var/www/html
/usr/local/bin/composer install
chown centos:apache /var/www/html -R
chmod 2775 /var/www/html -R


pubip=`dig +short myip.opendns.com @resolver1.opendns.com`
adminfirst=easydeploy
adminlast=cloud
admin=admin
ADMINPASS=`openssl rand -hex 12`
backend=admin_nslf
php bin/magento setup:install --base-url="http://$pubip" --db-host="localhost" --db-name="$NEWDBNAME" --db-user="$NEWDBUSER" --db-password="$PASS" --admin-firstname="$adminfirst" --admin-lastname="$adminlast" --admin-email=support@easydeploy.cloud --admin-user="$admin" --admin-password="$ADMINPASS" --backend-frontname="$backend"

touch /home/centos/MagentoAdmin.Credentials
echo admin_first_name=$adminfirst > /home/centos/MagentoAdmin.Credentials
echo admin_last_name=$adminlast >> /home/centos/MagentoAdmin.Credentials
echo admin_username=$admin >> /home/centos/MagentoAdmin.Credentials
echo admin_password=$ADMINPASS >> /home/centos/MagentoAdmin.Credentials
echo backend_URL=$backend  >> /home/centos/MagentoAdmin.Credentials
