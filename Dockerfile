FROM debian:buster

# autoindexを切り替えるための環境変数
ENV AUTOINDEX=on

ENV DEBCONF_NOWARNINGS yes

RUN apt-get update; \
	apt-get -y install vim \
	curl \
	wget \
	nginx \
	mariadb-server \
	mariadb-client \
	php-fpm \
	php-mysql \
	php-cgi \
	php-common \
	php-pear \
	php-mbstring \
	php-zip \
	php-net-socket \
	php-gd \
	php-xml-util \
	php-gettext \
	php-bcmath \
	unzip \
	#apt-getのcache削除
	&& rm -rf /var/lib/apt/lists/*;

# nginx
COPY srcs/default /etc/nginx/sites-available/default
COPY srcs/autoindex.sh /tmp/

# ssl
RUN mkdir /etc/nginx/ssl;
RUN apt-get -y install openssl; \
	openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -out /etc/nginx/ssl/server.crt \
            -keyout /etc/nginx/ssl/server.key \
			-subj '/C=JP/ST=Tokyo/L=Tokyo/O=42Tokyo/OU=42Tokyo/CN=example.com';

# mysql
RUN service mysql start; \
	service mysql -u root -p; \
	mysql -e "CREATE DATABASE IF NOT EXISTS 42tokyo;"; \
	mysql -e "CREATE USER 'kyuki'@'localhost' identified by 'kyuki';"; \
	mysql -e "GRANT ALL ON 42tokyo.* TO 'kyuki'@'localhost'"; \
	mysql -e "FLUSH PRIVILEGES;";

WORKDIR /var/www/html/.
# wordpress
RUN wget https://wordpress.org/latest.tar.gz; \
	tar -xvzf latest.tar.gz; \
	rm -rf latest.tar.gz;
COPY srcs/wp-config.php ./wordpress/.

# phpmyadmin
RUN	wget https://files.phpmyadmin.net/phpMyAdmin/5.0.4/phpMyAdmin-5.0.4-all-languages.tar.gz; \
	tar xvzf phpMyAdmin-5.0.4-all-languages.tar.gz; \
	mv phpMyAdmin-5.0.4-all-languages phpMyAdmin; \
	rm -rf phpMyAdmin-5.0.4-all-languages.tar.gz;

WORKDIR /

RUN chown -R www-data:www-data /var/www/html/wordpress; \
	chown -R www-data:www-data /var/www/html/phpMyAdmin;

EXPOSE 80 443
CMD bash /tmp/autoindex.sh; \
	service php7.3-fpm start; \
	service nginx start; \
	service mysql start; \
	tail -f /dev/null
