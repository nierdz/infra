FROM php:7.3-fpm
RUN docker-php-ext-install mysqli
RUN pecl install redis-4.2.0 && \
	docker-php-ext-enable redis
