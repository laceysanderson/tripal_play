# Docker Drupal DEV CI

This repository will be for development of a Docker image to use Drupal 8 in CI.

Currently we have the following installed:
 - Debian Stretch(9)
 - PHP 7.3 + extensions needed for Drupal
 - Apache2
 - Composer
 - Drupal 8.8-dev downloaded using composer.

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

4. Navigate to `http://localhost:9000/tripal4/web/` to use your newly installed site!
