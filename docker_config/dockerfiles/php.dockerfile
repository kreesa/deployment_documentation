FROM php:8-fpm-alpine3.14

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

ADD ./php/php.ini /usr/local/etc/php/php.ini

RUN mkdir -p /var/www/html/imis

WORKDIR /var/www/html/imis

# MacOS staff group's gid is 20, so is the dialout group in alpine linux. We're not using it, let's just remove it.
RUN delgroup dialout

RUN addgroup -g ${GID} --system laravel
RUN adduser -G laravel --system -D -s /bin/sh -u ${UID} laravel

RUN sed -i "s/user = www-data/user = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

RUN set -ex \
  && apk add \
    postgresql-dev

RUN apk --no-cache update \
    && apk --no-cache upgrade \
    && apk add libpng \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    zlib-dev \
    libxpm-dev \
    libxrender \
    libxext \
    fontconfig \
    gd

RUN docker-php-ext-configure gd --enable-gd --with-jpeg

RUN docker-php-ext-install pdo pdo_mysql -j$(nproc) gd pdo_pgsql pgsql

RUN apk add --no-cache wkhtmltopdf xvfb ttf-dejavu ttf-droid ttf-freefont ttf-liberation

COPY crontab /etc/crontabs/root

CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
