# NGINX Webserver for Single Page Apps

NGINX configuration based on [ubi-minimal](https://developers.redhat.com/products/rhel/ubi/) and with selected CIS Benchmarks.

## Quickstart

```sh
# Build image
docker build . -t nginx:cis

# Run image
docker run --rm -it -p 8080:8080 nginx:cis
```
