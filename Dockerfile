FROM httpd:2.2.34-alpine

WORKDIR /usr/local/apache2/htdocs/

COPY index.html .
