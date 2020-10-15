#!/bin/bash
yum update -y
yum install expat-devel pcre pcre-devel openssl-devel wget autoconf libtool libxml2-devel libcurl make gcc python3 python3-dev python3-pip -y

cp httpd-2.4.46.tar.gz /usr/local/src/
cp apr-1.7.0.tar.gz /usr/local/src/
cp apr-util-1.6.1.tar.gz /usr/local/src/

tar -zxvf /usr/local/src/httpd-2.4.46.tar.gz -C /usr/local/src
tar -zxvf /usr/local/src/apr-1.7.0.tar.gz -C /usr/local/src
tar -zxvf /usr/local/src/apr-util-1.6.1.tar.gz -C /usr/local/src

mv /usr/local/src/apr-1.7.0 /usr/local/src/httpd-2.4.46/srclib/apr
mv /usr/local/src/apr-util-1.6.1 /usr/local/src/httpd-2.4.46/srclib/apr-util

cd /usr/local/src/httpd-2.4.46 && \
	./buildconf && \
	./configure --enable-ssl --enable-so --with-mpm=event --with-included-apr --prefix=/usr/local/apache2 && \
	make && \
	make install
cd /root/waf/
cp httpd.sh /etc/profile.d/
cp httpd.service /etc/systemd/system/

groupadd www
useradd apache2 -g www --no-create-home --shell /sbin/nologin

mv /usr/local/apache2/conf/httpd.conf /usr/local/apache2/conf/httpd.con.bak
cp httpd.conf /usr/local/apache2/conf/

mkdir /opt/waf
mkdir /opt/waf/logs
mkdir /opt/waf/logs/access_log
mkdir /opt/waf/logs/error_log

cp modsecurity-2.9.3.tar.gz /usr/local/src/

tar -zxvf /usr/local/src/modsecurity-2.9.3.tar.gz -C /usr/local/src
cd /usr/local/src/modsecurity-2.9.3 && \
	./configure --prefix=/opt/waf --with-apxs=/usr/local/apache2/bin/apxs --with-apr=/usr/local/apache2/bin/apr-1-config --with-apu=/usr/local/apache2/bin/apr-1-config && \
	make && \
	make install && \
	cp unicode.mapping /usr/local/apache2/conf/extra
cd /root/waf/

cp modsecurity.conf /usr/local/apache2/conf/extra/
cp modsecurity_template.conf /usr/local/apache2/conf/extra/

cd /usr/local/apache2/conf && \
	mkdir sites-enabled
cd /root/waf/
cp template.vhosts.conf /usr/local/apache2/conf/sites-enabled

cp v3.3.0.tar.gz /usr/local/src/
tar -zxvf /usr/local/src/v3.3.0.tar.gz -C /usr/local/src && \
	mv /usr/local/src/coreruleset-3.3.0 /opt/waf/crs-rules && \
	cp /opt/waf/crs-rules/crs-setup.conf.example /opt/waf/crs-rules/crs-setup.conf

rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cp elastic.repo /etc/yum.repos.d/
yum install filebeat -y && \
	mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bak
cp filebeat.yml /etc/filebeat/