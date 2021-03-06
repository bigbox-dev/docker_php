FROM wodby/base-php:7.1.9

ENV GOTPL_VER="0.1.5" \
    PHP_PRESTISSIMO_VER="0.3" \
    PHP_UNIT_VER="6.3" \
    WALTER_VER="1.3.0" \

    EXT_AMQP_VER="1.9.1" \
    EXT_APCU_VER="5.1.8" \
    EXT_AST_VER="0.1.5" \
    EXT_IMAGICK_VER="3.4.3" \
    EXT_MEMCACHED_VER="3.0.3" \
    EXT_MONGODB_VER="1.1.10" \
    EXT_OAUTH_VER="2.0.2" \
    EXT_REDIS_VER="3.1.3" \
    EXT_XDEBUG_VER="2.5.5" \
    EXT_YAML_VER="2.0.2" \

    C_CLIENT_VER="2007f-r6" \
    FREETYPE_VER="2.7.1-r1" \
    ICU_LIBS_VER="58.2-r2" \
    IMAGEMAGICK_VER="7.0.5.10-r0" \
    LIBBZ2_VER="1.0.6-r5" \
    LIBJPEG_TURBO_VER="1.5.1-r0" \
    LIBLDAP_VER="2.4.44-r5" \
    LIBLTDL_VER="2.4.6-r1" \
    LIBMEMCACHED_LIBS_VER="1.0.18-r1" \
    LIBMCRYPT_VER="2.5.8-r7" \
    LIBPNG_VER="1.6.29-r1" \
    LIBXSLT_VER="1.1.29-r3" \
    MARIADB_CLIENT_VER="10.1.26-r0" \
    POSTGRESQL_CLIENT_VER="9.6.6-r0" \
    RABBITMQ_C_VER="0.8.0-r2" \
    YAML_VER="0.1.7-r0"

ENV EXT_AST_URL="https://github.com/nikic/php-ast/archive/v${EXT_AST_VER}.tar.gz" \
    EXT_UPLOADPROGRESS_URL="https://github.com/wodby/pecl-php-uploadprogress/archive/latest.tar.gz" \
    GOTPL_URL="https://github.com/wodby/gotpl/releases/download/${GOTPL_VER}/gotpl-alpine-linux-amd64-${GOTPL_VER}.tar.gz" \
    WALTER_URL="https://github.com/walter-cd/walter/releases/download/v${WALTER_VER}/walter_${WALTER_VER}_linux_amd64.tar.gz" \
    BLACKFIRE_URL="https://blackfire.io/api/v1/releases/probe/php/alpine/amd64" \

    PATH="/root/.composer/vendor/bin:${PATH}"


ENV PHP_REALPATH_CACHE_TTL="3600" \
    PHP_OUTPUT_BUFFERING="16384" \

    DRUSH_PATCHFILE_URL="https://bitbucket.org/davereid/drush-patchfile.git"


RUN set -xe && \

    # Recreate user with correct params
    deluser www-data && \
	addgroup -g 82 -S www-data && \
	adduser -u 82 -D -S -s /bin/bash -G www-data www-data && \
	sed -i '/^www-data/s/!/*/' /etc/shadow && \

    apk add --update --no-cache --virtual .php-rundeps \
        bash \
        ca-certificates \
        c-client=${C_CLIENT_VER} \
        fcgi \
        freetype=${FREETYPE_VER} \
        git \
        gzip \
        icu-libs=${ICU_LIBS_VER} \
        imagemagick=${IMAGEMAGICK_VER} \
        libbz2=${LIBBZ2_VER} \
        libjpeg-turbo=${LIBJPEG_TURBO_VER} \
        libldap=${LIBLDAP_VER} \
        libltdl=${LIBLTDL_VER} \
        libmemcached-libs=${LIBMEMCACHED_LIBS_VER} \
        libmcrypt=${LIBMCRYPT_VER} \
        libpng=${LIBPNG_VER} \
        libxslt=${LIBXSLT_VER} \
        make \
        mariadb-client=${MARIADB_CLIENT_VER} \
        openssh \
        openssh-client \
        patch \
        postgresql-client=${POSTGRESQL_CLIENT_VER} \
        rabbitmq-c=${RABBITMQ_C_VER} \
        rsync \
        su-exec \
        tar \
        wget \
        yaml=${YAML_VER} && \

    apk add --update --no-cache --virtual .build-deps \
        autoconf \
        cmake \
        build-base \
        bzip2-dev \
        freetype-dev \
        icu-dev \
        imagemagick-dev \
        imap-dev \
        jpeg-dev \
        libjpeg-turbo-dev \
        libmemcached-dev \
        libmcrypt-dev \
        libpng-dev \
        libtool \
        libxslt-dev \
        openldap-dev \
        pcre-dev \
        postgresql-dev \
        rabbitmq-c-dev \
        yaml-dev && \

    docker-php-source extract && \

    docker-php-ext-install \
        bcmath \
        bz2 \
        calendar \
        exif \
        imap \
        intl \
        ldap \
        mcrypt \
        mysqli \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        phar \
        soap \
        sockets \
        xmlrpc \
        xsl \
        zip && \

    # GD
    docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ && \
      NPROC=$(getconf _NPROCESSORS_ONLN) && \
      docker-php-ext-install -j${NPROC} gd && \

    # PECL extensions
    pecl config-set php_ini "${PHP_INI_DIR}/php.ini" && \

    pecl install -f \
        amqp-${EXT_AMQP_VER} \
        imagick-${EXT_IMAGICK_VER} \
        memcached-${EXT_MEMCACHED_VER} \
        mongodb-${EXT_MONGODB_VER} \
        oauth-${EXT_OAUTH_VER} \
        redis-${EXT_REDIS_VER} \
        xdebug-${EXT_XDEBUG_VER} \
        yaml-${EXT_YAML_VER} && \

    docker-php-ext-enable \
        amqp \
        imagick \
        memcached \
        mongodb \
        oauth \
        redis \
        xdebug \
        yaml 

    # Uploadprogress
RUN mkdir -p /usr/src/php/ext/uploadprogress && \
    wget -qO- ${EXT_UPLOADPROGRESS_URL} | tar xz --strip-components=1 -C /usr/src/php/ext/uploadprogress && \
    docker-php-ext-configure uploadprogress && \
    docker-php-ext-install uploadprogress && \

     # Install Gotpl
    wget -qO- ${GOTPL_URL} | tar xz -C /usr/local/bin && \

    # Install composer
    wget -qO- https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \

    # Plugin for parallel install
    su-exec root composer global require hirak/prestissimo:^${PHP_PRESTISSIMO_VER} && \

    # Install PHPUnit
    wget -qO- https://phar.phpunit.de/phpunit-${PHP_UNIT_VER}.phar > /usr/local/bin/phpunit && \
    chmod +x /usr/local/bin/phpunit && \

    # Update SSHd config
    echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /etc/ssh/ssh_config && \
    sed -i '/PermitUserEnvironment/c\PermitUserEnvironment yes' /etc/ssh/sshd_config && \
    sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config && \
    echo "root:root" | chpasswd && \

    # Add composer bins to $PATH
    su-exec root echo "export PATH=/root/.composer/vendor/bin:${PATH}" > /root/.profile && \

    # Clean up root crontab
    truncate -s 0 /etc/crontabs/root && \

    # Cleanup
    su-exec root composer clear-cache && \
    docker-php-source delete && \
    apk del .build-deps && \
    pecl clear-cache && \

    rm -rf \
        /usr/src/php.tar.xz \
        /usr/src/php/ext/ast \
        /usr/src/php/ext/uploadprogress \
        /usr/include/php \
        /usr/lib/php/build \
        /tmp/* 



RUN su-exec root composer global require drush/drush
RUN    su-exec root composer clear-cache
RUN echo $PATH && ls -la /root/.composer/vendor/bin && /root/.composer/vendor/bin/drush
RUN    su-exec root drush @none dl registry_rebuild-7.x 
RUN    su-exec root git clone ${DRUSH_PATCHFILE_URL} /root/.drush/drush-patchfile && \
    su-exec root drush cc drush && \
    curl https://drupalconsole.com/installer -L -o drupal.phar && \
    mv drupal.phar /usr/local/bin/drupal && \
    chmod +x /usr/local/bin/drupal
    
ENV APP_ROOT="/srv/www/"

WORKDIR ${APP_ROOT}
EXPOSE 9000
EXPOSE 22

COPY templates /etc/gotpl/
COPY docker-entrypoint.sh /


ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["php-fpm"]
