FROM rlukman/php-httpd

# add bitbucket and github to known hosts for ssh needs
#WORKDIR /root/.ssh
#RUN chmod 0600 /root/.ssh \
#    && ssh-keyscan -t rsa bitbucket.org >> known_hosts \
#    && ssh-keyscan -t rsa github.com >> known_hosts

##
## Compose Package Manager
##

# install composer dependencies
WORKDIR /var/www/sdlt

#COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data ./composer.json ./composer.lock* ./
ENV COMPOSER_VENDOR_DIR=/var/www/sdlt/vendor
# RUN composer config github-oauth.github.com YOUROAUTHKEYHERE
# RUN composer install --no-scripts --no-autoloader --ansi --no-interaction

RUN composer install


##
## Node Build Tools
##

# we hardcode to develop so all tools are there for npm build
#ENV NODE_ENV=develop
# install dependencies first, in a different location for easier app bind mounting for local development
#WORKDIR /var/www
#COPY ./themes/sdlt/package.json .
#RL
# RUN npm install
# no need to cache clean in non-final build steps
#ENV PATH /var/www/node_modules/.bin:$PATH
#ENV NODE_PATH=/var/www/node_modules
#WORKDIR /var/www/app

##
## We Are Go for Bower
##

# If you were to use Bower, this might be how to do it
# COPY ./bower.json .
# RUN bower install --allow-root

# add custom php-fpm pool settings, these get written at entrypoint startup
#ENV FPM_PM_MAX_CHILDREN=20 \
#    FPM_PM_START_SERVERS=2 \
#    FPM_PM_MIN_SPARE_SERVERS=1 \
#    FPM_PM_MAX_SPARE_SERVERS=3

# Laravel App Config
# setup app config environment at runtime
# gets put into ./.env at startup
#ENV APP_NAME=sdlt \
#    APP_ENV=local \
#    APP_DEBUG=true \
#    APP_KEY=KEYGOESHERE \
#    APP_LOG=errorlog \
#    APP_URL=http://localhost \
#    DB_CONNECTION=mysql \
#    DB_HOST=sdlt_mysql_1 \
#    DB_PORT=3306 \
#    DB_DATABASE=sdlt \
#    DB_USERNAME=admin01 \
#    DB_PASSWORD=mypassword01
# Many more ENV may be needed here, and updated in docker-php-entrypoint file


# update the entrypoint to write config files and do last minute builds on startup
# notice we have a -dev version, which does different things on local docker-compose
# but we'll default to entrypoint of running the non -dev one

#COPY --chown=www-data:www-data docker-php-* /usr/local/bin/
#RUN dos2unix /usr/local/bin/docker-php-entrypoint
#RUN dos2unix /usr/local/bin/docker-php-entrypoint-dev


# copy in nginx config
#COPY --chown=www-data:www-data ./nginx.conf /etc/nginx/nginx.conf
#COPY --chown=www-data:www-data ./nginx-site.conf /etc/nginx/conf.d/default.conf

#RL
# copy in app code as late as possible, as it changes the most

WORKDIR /var/www/sdlt
# COPY --chown=www-data:www-data . .
# copy apps files
RUN composer dump-autoload -o

# be sure nginx is properly passing to php-fpm and fpm is responding
#HEALTHCHECK --interval=5s --timeout=3s \
#  CMD curl -f http://localhost/ping || exit 1

#WORKDIR /var/www/sdlt/public
# copy apps files from public folder
# following SDLT instruction guide 
WORKDIR /var/www/sdlt
COPY --chown=www-data:www-data . .
RUN cp ./.env.example ./.env 

# WORKDIR /var/www/sdlt/vendor/bin
# RL remarked off the below part as this can only be executed when container is up and running ,
# use the http://localhost/dev to do the same setup instead
#RUN ./sake dev/build flush=

WORKDIR /var/www/sdlt
RUN rm /var/www/sdlt/public/resources/themes/sdlt/dist && \
    cp -r /var/www/sdlt/themes/* /var/www/sdlt/public/resources/themes/ &&\
    mkdir /var/www/sdlt/public/resources/vendor && \
    cp -r /var/www/sdlt/vendor/* /var/www/sdlt/public/resources/vendor/ &&\
# to increase the default setting to avoid timeout during initial SDLT task to generate default data / dashboard
    sed -i -e 's/max_execution_time = 30/max_execution_time = 120/g' \  
      -e 's/max_input_time = 60/max_input_time = 120/g' \
      -e 's/default_socket_timeout = 60/default_socket_timeout = 120/g' /usr/local/etc/php/php.ini-production  &&\
        cp  /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini 

# just for dev purpose - to be removed for PROD!
RUN echo "<?php phpinfo(); ?>" > ./public/phpinfo.php

#RUN cp ./.env.example ./.env && \
#  mkdir /var/www/sdlt/public/assets/ && \
#  cp -r /var/www/sdlt/vendor/silverstripe/assets/* /var/www/sdlt/public/assets/ && \
#  mkdir /var/www/sdlt/_config/  && \
#  cp -r /var/www/sdlt/vendor/silverstripe/assets/_config /var/www/sdlt/_config && \
#  chown -R www-data:www-data /var/www/sdlt && \
#  chmod -R 755 /var/www/sdlt

# Apache + xdebug configuration
RUN { \
                echo "<VirtualHost *:80>"; \
                echo "ServerAdmin noreply@noreply.org";\
                echo "  DocumentRoot /var/www/sdlt/public"; \
                echo "  LogLevel warn"; \
                echo "  ErrorLog /var/log/apache2/error.log"; \
                echo "  CustomLog /var/log/apache2/access.log combined"; \
                echo "  ServerSignature Off"; \
                echo "  UseCanonicalName Off"; \
                echo "  <Directory /var/www/sdlt/public>"; \
                echo "    Options Indexes FollowSymLinks MultiViews"; \
                echo "    AllowOverride All";\
                echo "    Order allow,deny";\
                echo "    Allow from all";\
                echo "    Require all granted";\
                echo "  </Directory>"; \
                echo "  <Directory /var/www/sdlt/themes>"; \
                echo "    Options Indexes FollowSymLinks MultiViews"; \
                echo "    AllowOverride All";\
                echo "    Order allow,deny";\
                echo "    Allow from all";\
                echo "    Require all granted";\
                echo "  </Directory>"; \
                echo; \
                echo "  IncludeOptional sites-available/000-default.local*"; \
                echo "</VirtualHost>"; \
	} | tee /etc/apache2/sites-available/000-default.conf

EXPOSE 80 443 9000 9001
CMD ["apache2-foreground"]
#CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
