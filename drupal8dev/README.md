# Docker Drupal DEV CI

This repository will be for development of a Docker image to use Drupal 8 in CI.

Currently we have the following installed:

   - Debian Buster(10)
   - PHP 7.3.18 + extensions needed for Drupal (Memory limit 1028M)
   - Apache 2.4.38
   - PostgreSQL 11.7
   - Composer 1.10.10
   - Drupal 8.9.3 (8.x-dev) downloaded using composer.


1. Build the docker image:
```
docker build -t="drupal8dev_ci" .
```
2. Run the image in the background mapping it's webserver to your port 9000:
```
docker run --publish=9000:80 --name=drupal8dev_ci -t -i -d drupal8dev_ci
```
3. Start the database in your container.
```
docker exec drupal8dev_ci service postgresql start
```
NOTE: it takes a little while for the database to start. If the website doesn't load, wait a little longer and try again.

4. Navigate to `http://localhost:9000` to use your newly installed site! The administration user is drupaladmin:some_admin_password

5. Run some PHPunit tests.
```
docker exec drupal8dev_ci ../vendor/phpunit/phpunit/phpunit --configuration core core/modules/simpletest/tests
```
