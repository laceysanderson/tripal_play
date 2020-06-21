
FROM laceysanderson/drupal9dev_ci:drupal9.0.x-php7.3
MAINTAINER Lacey-Anne Sanderson <laceyannesanderson@gmail.com>

COPY . /app

RUN cd /var/www/html/drupal9/web/modules \
  && git clone --single-branch --branch 9.x-4.x https://github.com/tripal/t4d8.git

RUN cd /var/www/html/drupal9 \
  && service apache2 start \
  && service postgresql start \
  && sleep 30 \
  && vendor/bin/drush en tripal tripal_chado -y \
  && vendor/bin/drush php-eval "module_load_include('inc', 'tripal_chado', 'src/LegacyIncludes/tripal_chado.install'); tripal_chado_install_chado('Install Chado v1.3');"
