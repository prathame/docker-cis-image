# Stage 1 - Build base image with nginx
# Set DOCKER_BUILDKIT=0
ARG DOCKER_BUILDKIT=0
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
FROM base AS final

#WORKDIR /usr/share/nginx/html/

#COPY --chown=nginx --from=builder /app .

USER nginx
RUN echo "Ensure NGINX is installed:" 
RUN nginx -v
RUN echo "Ensure package manager repositories are properly configured:"
RUN cat /etc/yum.repos.d/*.repo
RUN echo "Ensure the latest software package is installed:"
RUN rpm -q -a --qf "%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n" | sort
RUN echo "Ensure HTTP WebDAV module is not installed :"
RUN echo rpm -q mod_dav_svn
RUN echo "Ensure the NGINX process ID (PID) file is secured"
RUN ls -l /var/run/nginx.pid
RUN echo "Ensure the core dump directory is secured :"
RUN ls -ld /var/lib/systemd/coredump/
RUN echo "Ensure keepalive_timeout is 10 seconds or less, but not 0: "
RUN grep "keepalive_timeout" /etc/nginx/nginx.conf
RUN echo "Ensure send_timeout is set to 10 seconds or less, but not 0:"
RUN grep "send_timeout" /etc/nginx/nginx.conf
RUN echo "Ensure server_tokens directive is set to off: "
RUN grep "server_tokens" /etc/nginx/nginx.conf
RUN echo "Ensure default error and index.html pages do not reference NGINX: "
RUN cat /usr/share/nginx/html/index.html
RUN echo "Ensure hidden file serving is disabled: "
RUN grep "location ~ " /etc/nginx/nginx.conf
RUN echo "Ensure access logging is enabled: "
RUN grep "/var/log/nginx/access.log  main" /etc/nginx/nginx.conf
RUN echo "Ensure error logging is enabled and set to the info logging level: "
RUN grep "error_log" /etc/nginx/nginx.conf
RUN echo "Ensure X-Frame-Options header is configured and enabled: "
RUN grep "add_header X-Frame-Options" /etc/nginx/nginx.conf
RUN echo "Ensure the X-XSS-Protection Header is enabled and configured properly: "
RUN grep "add_header X-Xss-Protection" /etc/nginx/nginx.conf
RUN echo "Ensure X-Content-Type-Options header is configured and enabled: "
RUN grep "add_header X-Content-Type-Options" /etc/nginx/nginx.conf
CMD ["nginx", "-g", "daemon off;"]
