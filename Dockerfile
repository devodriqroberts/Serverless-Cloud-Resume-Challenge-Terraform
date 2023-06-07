# Nginx Latest
FROM nginx

RUN mkdir -p /usr/src/site

WORKDIR /usr/src/site

COPY ./resume-site .

COPY ./resume-site /usr/share/nginx/html
