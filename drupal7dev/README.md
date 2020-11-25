![Tripal Dependency](https://img.shields.io/badge/tripal-%3E=3.0-brightgreen)

# UofS Tripal Docker

## Usage

1) Pull the most recent image from the Github Package Repository.

```
docker pull laceysanderson/drupal7dev
```

2) Create a running container exposing the website at localhost:8888

To customize the installed site, change the variables available in the .env file without removing any. Make sure to change DBPASS and ADMINPASS for security reasons.

```
docker run --publish=8888:80 --name=tdocker -tid \
  -e DBPASS='somesecurepassword' \
  -e ADMINPASS='anothersecurepassword' \
  --env-file=.env \
  laceysanderson/drupal7dev:latest
```

3) Provision the container including installation of the software stack including default configuration.

```
docker exec -it tdocker /app/init_scripts/startup_container.sh
```

### For development on a specific module

1) Pull the most recent image from the Github Package Repository.

```
docker pull laceysanderson/drupal7dev
```

2) Pull your module. I suggest creating a dockers directory to ensure you can find the directory to mapped to your container ;-p

```
cd ~/Dockers
git clone https://github.com/tripal/tripal
cd tripal
```

3) Create a running container exposing the website at localhost:8888 and mounting your current directory inside the container.

 - **Make sure to change the directory below from tripal to the machine name of your module.**
 - Copy the .env file from this repository into your module directory. **DO NOT COMMIT THIS FILE**
 - To customize the installed site, change the variables available in the .env file without removing any. Make sure to change DBPASS and ADMINPASS for security reasons.
 - Your website admin is tripaladmin with the password set in the run command below.

```
docker run --publish=8888:80 --name=tdocker -tid \
  -e DBPASS='somesecurepassword' \
  -e ADMINPASS='anothersecurepassword' \
  --env-file=.env \
	--volume=`pwd`:/var/www/html/sites/all/modules/tripal \
  laceysanderson/drupal7dev:latest
```

4) Provision the container including installation of the software stack including default configuration.

```
docker exec -it tdocker /app/init_scripts/startup_container.sh
```
