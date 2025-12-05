FROM httpd:2.4.66-alpine

WORKDIR /usr/local/apache2/htdocs/

COPY index.html .
