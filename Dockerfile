FROM php:7.3-apache-stretch

## Base of this image is from Official DockerHub drupal image. Specifically,
## https://github.com/docker-library/drupal/blob/master/8.8/apache/Dockerfile
## Heavily influenced by https://github.com/statonlab/docker-containers

MAINTAINER Lacey-Anne Sanderson <laceyannesanderson@gmail.com>

COPY . /app

RUN chmod -R +x /app && apt-get update 1> ~/aptget.update.log \
  && apt-get install git unzip zip supervisor --yes -qq 1> ~/aptget.extras.log

# install the PHP extensions we need
RUN set -eux; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype-dir=/usr \
		--with-jpeg-dir=/usr \
		--with-png-dir=/usr \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /var/www/html

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php -r "if (hash_file('sha384', 'composer-setup.php') === 'c5b9b6d368201a9db6f74e2611495f369991b72d9c8cbd3ffbc63edff210eb73d46ffbfce88669ad33695ef77dc76976') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
  && php composer-setup.php \
  && mv composer.phar /usr/local/bin/composer

RUN composer create-project drupal-composer/drupal-project:8.x-dev tripal4 --stability dev --no-interaction

# Set files directory permissions
RUN chown -R www-data:www-data /var/www/html/tripal4/web/sites/default/files

# Expose http and psql port
EXPOSE 80 5432

# Configuration files
COPY supervisord.conf /etc/supervisord.conf
COPY apache.conf /etc/httpd/conf.d/apache.conf

# Activation scripts
COPY init.sh /usr/bin/init.sh
RUN chmod +x /usr/bin/init.sh

ENTRYPOINT ["init.sh"]
