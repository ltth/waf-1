FROM centos:7
RUN yum update -y
RUN yum install expat-devel pcre pcre-devel openssl-devel wget autoconf libtool libxml2-devel libcurl make -y

COPY file /usr/bin/.
COPY which /usr/bin/.
COPY httpd-2.4.46.tar.gz /usr/local/src/
COPY apr-1.7.0.tar.gz /usr/local/src/
COPY apr-util-1.6.1.tar.gz /usr/local/src/

RUN tar -zxvf /usr/local/src/httpd-2.4.46.tar.gz -C /usr/local/src
RUN tar -zxvf /usr/local/src/apr-1.7.0.tar.gz -C /usr/local/src
RUN tar -zxvf /usr/local/src/apr-util-1.6.1.tar.gz -C /usr/local/src

RUN mv /usr/local/src/apr-1.7.0 /usr/local/src/httpd-2.4.46/srclib/apr
RUN mv /usr/local/src/apr-util-1.6.1 /usr/local/src/httpd-2.4.46/srclib/apr-util

RUN cd /usr/local/src/httpd-2.4.46 && \
	./buildconf && \
	./configure --enable-ssl --enable-so --with-mpm=event --with-included-apr --prefix=/usr/local/apache2 && \
	make && \
	make install
COPY httpd.sh /etc/profile.d/
COPY httpd.service /etc/systemd/system/

#RUN systemctl daemon-reload
#RUN systemctl start httpd

RUN groupadd www
RUN useradd apache2 -g www --no-create-home --shell /sbin/nologin

#config apache2
RUN mv /usr/local/apache2/conf/httpd.conf /usr/local/apache2/conf/httpd.con.bak
COPY httpd.conf /usr/local/apache2/conf/

#build modesecurity
RUN mkdir /opt/waf && \
	mkdir /opt/waf/logs && \
	mkdir /opt/waf/logs/access_log && \
	mkdir /opt/waf/logs/error_log

COPY modsecurity-2.9.3.tar.gz /usr/local/src/

RUN tar -zxvf /usr/local/src/modsecurity-2.9.3.tar.gz -C /usr/local/src
RUN cd /usr/local/src/modsecurity-2.9.3 && \
	./configure --prefix=/opt/waf --with-apxs=/usr/local/apache2/bin/apxs --with-apr=/usr/local/apache2/bin/apr-1-config --with-apu=/usr/local/apache2/bin/apr-1-config && \
	make && \
	make install && \
	cp unicode.mapping /usr/local/apache2/conf/extra

COPY modsecurity.conf /usr/local/apache2/conf/extra/
COPY modsecurity_template.conf /usr/local/apache2/conf/extra/

RUN cd /usr/local/apache2/conf && \
	mkdir sites-enabled
COPY template.vhosts.conf /usr/local/apache2/conf/sites-enabled

#install CRS

COPY v3.3.0.tar.gz /usr/local/src/
RUN tar -zxvf /usr/local/src/v3.3.0.tar.gz -C /usr/local/src && \
	mv /usr/local/src/coreruleset-3.3.0 /opt/waf/crs-rules && \
	cp /opt/waf/crs-rules/crs-setup.conf.example /opt/waf/crs-rules/crs-setup.conf

#install filebeat

RUN rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
COPY elastic.repo /etc/yum.repos.d/
RUN yum install filebeat -y && \
	mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bak
COPY filebeat.yml /etc/filebeat/
RUN systemctl enable filebeat

EXPOSE 80
EXPOSE 443