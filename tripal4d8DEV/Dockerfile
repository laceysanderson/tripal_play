
FROM laceysanderson/drupal8dev_ci:drupal8.9.3-pgsql
MAINTAINER Lacey-Anne Sanderson <laceyannesanderson@gmail.com>

COPY . /app

RUN cd /var/www/html/drupal8/web/modules \
  && git clone --single-branch --branch 9.x-4.x https://github.com/tripal/t4d8.git

RUN cd /var/www/html/drupal8 \
  && service apache2 start \
  && service postgresql start \
  && sleep 30 \
  && composer require drupal/devel \
  && composer require drupal/console:~1.0 --prefer-dist --optimize-autoloader \
  && vendor/bin/drush en devel tripal tripal_chado -y \
  && vendor/bin/drush php-eval "module_load_include('inc', 'tripal_chado', 'src/LegacyIncludes/tripal_chado.install'); tripal_chado_install_chado('Install Chado v1.3');"
