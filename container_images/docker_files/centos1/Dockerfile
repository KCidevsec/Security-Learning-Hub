FROM arm64v8/centos:7
LABEL Author="Kyriakos_Costa"
LABEL Email="kyriakoskosta@gmai.com"

RUN yum makecache
RUN yum -y install epel-release
RUN yum update -y
RUN yum install -y \
	nginx \
	php \
	php-mysql \
	php-fpm \
	openssh-server \
	openssh-clients

COPY webfiles /data/www

COPY configfiles/nginx.conf /etc/nginx/nginx.conf
COPY configfiles/php.ini /etc/php.ini
COPY configfiles/www.conf /etc/php-fpm.d/www.conf
COPY webfiles/ /usr/share/nginx/html
COPY configfiles/docker-entrypoint.sh /

RUN rm -f /usr/share/nginx/html/index.html /usr/share/nginx/html/nginx-logo.png /usr/share/nginx/html/poweredby.png
RUN chmod +x /docker-entrypoint.sh

EXPOSE 22
EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
