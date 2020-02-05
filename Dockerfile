FROM php:7.3-apache-stretch

## Base of this image is from Official DockerHub drupal image. Specifically,
## https://github.com/docker-library/drupal/blob/master/8.8/apache/Dockerfile
## Heavily influenced by https://github.com/statonlab/docker-containers

MAINTAINER Lacey-Anne Sanderson <laceyannesanderson@gmail.com>

COPY . /app

RUN chmod -R +x /app && apt-get update 1> ~/aptget.update.log \
  && apt-get install git unzip zip wget gnupg2 supervisor --yes -qq 1> ~/aptget.extras.log

########## POTSGRESQL ###########################

# This seems to be needed though I'm not sure why.
# See https://stackoverflow.com/questions/51033689/how-to-fix-error-on-postgres-install-ubuntu
RUN mkdir -p /usr/share/man/man1 && mkdir -p /usr/share/man/man7

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.6``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Install PostgreSQL 9.6
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.6`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker \
    && psql --command="CREATE USER drupaladmin WITH PASSWORD 'drupal8developmentonlylocal'" \
    && psql --command="CREATE DATABASE drupal8_dev WITH OWNER drupaladmin"

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.6/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

USER root

########## PHP EXTENSIONS #######################
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
    echo 'opcache.memory_limit=768M';\
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN echo 'memory_limit = 1028M' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini

WORKDIR /var/www/html

############# DRUPAL ############################

ENV SIMPLETEST_BASE_URL=http://localhost/drupal8/web
ENV SIMPLETEST_DB=pgsql://drupaladmin:drupal8developmentonlylocal@localhost/drupal8_dev
ENV BROWSER_OUTPUT_DIRECTORY=/var/www/html/drupal8/web/sites/default/files/simpletest/output

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php -r "if (hash_file('sha384', 'composer-setup.php') === 'c5b9b6d368201a9db6f74e2611495f369991b72d9c8cbd3ffbc63edff210eb73d46ffbfce88669ad33695ef77dc76976') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
  && php composer-setup.php \
  && mv composer.phar /usr/local/bin/composer

RUN export COMPOSER_MEMORY_LIMIT=-1 \
  && composer create-project drupal-composer/drupal-project:8.x-dev drupal8 --stability dev --no-interaction

# Set files directory permissions
RUN chown -R www-data:www-data /var/www/html/drupal8 \
  && chmod 02775 -R /var/www/html/drupal8/web/sites/default/files \
  && usermod -g www-data root

# Expose http and psql port
EXPOSE 80 5432

RUN cd /var/www/html/drupal8 \
  && service apache2 start \
  && service postgresql start \
  && sleep 30 \
  && /var/www/html/drupal8/vendor/drush/drush/drush site-install standard \
  --db-url=pgsql://drupaladmin:drupal8developmentonlylocal@localhost/drupal8_dev \
  --account-mail="drupaladmin@localhost" \
  --account-name=drupaladmin \
  --account-pass=some_admin_password \
  --site-mail="drupaladmin@localhost" \
  --site-name="Drupal 8 Development"

# Configuration files
COPY supervisord.conf /etc/supervisord.conf
COPY apache.conf /etc/httpd/conf.d/apache.conf

# Activation scripts
COPY init.sh /usr/bin/init.sh
RUN chmod +x /usr/bin/init.sh

ENTRYPOINT ["init.sh"]
