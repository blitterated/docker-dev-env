# Docker Dev Environment

| [Project Goals](https://github.com/blitterated/docker_dev_env/wiki/Project-Goals) | [Project Questions](https://github.com/blitterated/docker_dev_env/wiki/Project-Questions) |
| ----- | ----- |

## Intent

This concept is not for creating containers ready for production deployment. Instead the intent is to code without polluting the development machine, and to deploy the project to a production runtime that is most likely not container based. It's simply another way to achieve a deeper kind of segregation along the lines of `virtualenv` or `bundle install --local`.

## Building and Running

### Build the docker-dev-env image from Dockerfile

```sh
docker build -t dde .
```

### Run the docker-dev-env image

```sh
docker run -it --rm dde /bin/bash
```

##  There's more info in the [wiki](https://github.com/blitterated/docker_dev_env/wiki)
