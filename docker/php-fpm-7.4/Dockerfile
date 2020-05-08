FROM php:7.4-fpm
LABEL version=1.0.0
RUN docker-php-ext-install mysqli \
  && pecl install redis-4.2.0 \
  && docker-php-ext-enable redis \
  && docker-php-ext-install mysqli \
  && docker-php-ext-install exif \
  && docker-php-ext-install opcache
