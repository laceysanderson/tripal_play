# Docker Drupal DEV CI

This repository will be for development of a Docker image to use Drupal 8 in CI.

Currently we have the following installed:
 - Debian Stretch(9)
 - PHP 7.3 + extensions needed for Drupal
 - Apache2
 - Composer
 - Drupal 8.8-dev downloaded using composer.
 
The image should be run using: `docker run --publish=9000:80 -t -i test /bin/bash` to map the webserver within the container to `http://localhost:9000` on your computer. Once in the container's command line via the run command, you need to start apache using `service apache2 start`. After this you can navigate to `http://localhost:9000/tripal4/web/` to install Drupal through the UI.

WARNING: Currently there is not database associated with this container.
