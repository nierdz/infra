FROM php:7.3-fpm
RUN docker-php-ext-install mysqli \
  && pecl install redis-4.2.0 \
  && docker-php-ext-enable redis \
  && docker-php-ext-install mysqli \
  && docker-php-ext-install exif \
  && docker-php-ext-install opcache
