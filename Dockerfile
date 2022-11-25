FROM php:8.0.9-fpm-alpine

RUN apk update; \
  apk upgrade;

# install packages
RUN apk add tzdata \
  nginx \
  supervisor \
  alpine-conf

RUN docker-php-ext-install mysqli
RUN docker-php-ext-install calendar
RUN docker-php-ext-configure calendar

# setting locales
ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"
# install libintl
# then install dev dependencies for musl-locales
# clone the sources
# build and install musl-locales
# remove sources and compile artifacts
# lastly remove dev dependencies again
RUN apk --no-cache add libintl && \
  apk --no-cache --virtual .locale_build add cmake make musl-dev gcc gettext-dev git && \
  git clone https://gitlab.com/rilian-la-te/musl-locales && \
  cd musl-locales && cmake -DLOCALE_PROFILE=OFF -DCMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install && \
  cd .. && rm -r musl-locales && \
  apk del .locale_build

ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE.UTF-8
ENV LC_ALL de_DE.UTF-8

# set timezone
RUN setup-timezone -z Europe/Berlin
RUN apk del tzdata

# copy app data
COPY nginx.conf /etc/nginx/
COPY supervisor.conf /etc/supervisor.conf
COPY api/ /var/www/html

# install compose and external sdk's
COPY dockerConfig/install_composer.sh /var/www/html
COPY api/composer.json /var/www/html
RUN sh /var/www/html/install_composer.sh
RUN php composer.phar install

# define start script
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor.conf"]

EXPOSE 80
