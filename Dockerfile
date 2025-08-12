FROM httpd:2.4.65-alpine

WORKDIR /usr/local/apache2/htdocs/

COPY index.html .
