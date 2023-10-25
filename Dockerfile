# Stage 1 - Build base image with nginx
ARG BASE_REGISTRY=registry.access.redhat.com
ARG BASE_IMAGE=ubi8/ubi-minimal
ARG BASE_TAG=latest

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as base

ARG BASE_REGISTRY
ARG BASE_IMAGE

RUN if [ "$BASE_REGISTRY/$BASE_IMAGE" == "registry.access.redhat.com/ubi8/ubi-minimal" ]; then \
        # install nginx
        microdnf install nginx && \
        microdnf clean all && \
        # remove unused modules
        rm -f \
            /usr/share/nginx/modules/mod-http-image-filter.conf \
            /usr/share/nginx/modules/mod-http-perl.conf \
            /usr/share/nginx/modules/mod-http-xslt-filter.conf \
            /usr/share/nginx/modules/mod-mail.conf && \
        rm -f \
            /usr/share/nginx/modules/ngx_http_image_filter_module.so \
            /usr/share/nginx/modules/ngx_http_perl_module.so \
            /usr/share/nginx/modules/ngx_http_xslt_filter_module.so \
            /usr/share/nginx/modules/2019 ngx_mail_module.so && \
        # pipe logs to stdout / stderr
        ln -sf /dev/stdout /var/log/nginx/access.log && \
        ln -sf /dev/stderr /var/log/nginx/error.log && \
        # replace error pages
        rm -rf /usr/share/nginx/html/* && \
        echo 'OK' > /usr/share/nginx/html/index.html && \
        echo 'The page you are looking for is temporarily unavailable. Please try again later.' > /usr/share/nginx/html/50x.html && \
        echo 'The page you are looking for is not found.' > /usr/share/nginx/html/40x.html && \
        # fix permissions
        chmod -R o-rwx /etc/nginx && \
        # fix nginx user permissions
        chown -R nginx:nginx /usr/share/nginx && \
        chown -R nginx:nginx /var/log/nginx && \
        chown -R nginx:nginx /etc/nginx && \
        touch /var/run/nginx.pid && \
        chown -R nginx:nginx /var/run/nginx.pid; \
    fi

COPY --chown=nginx nginx.conf /etc/nginx/
RUN chmod -R ug-x,o-rwx /etc/nginx/nginx.conf

# # Stage 2 - Build and Copy files
# FROM node:lts-alpine as builder
# WORKDIR /app
# RUN echo 'Hello from nginx' > /app/index.html

# Stage 3 - the production environment
FROM base as final

#WORKDIR /usr/share/nginx/html/

#COPY --chown=nginx --from=builder /app .

USER nginx

CMD ["nginx", "-g", "daemon off;"]
