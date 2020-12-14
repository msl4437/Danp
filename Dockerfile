# 指定创建的基础镜像
FROM alpine:3.11

# 作者描述信息
MAINTAINER msl4437(https://github.com/msl4437)

#变量
ENV PHP_VERSION=7.4.13 \
    Nginx_VERSION=1.14.2 \
    Apache_VERSION=2.4.46

RUN apk update && \
    apk add openssh && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    ssh-keygen -t dsa -P "" -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key && \
    
    #增加用户组
    addgroup -S www && \
    adduser -S www -G www -D -s /sbin/nologin && \
    chown -R www:www /home/www && \
    chmod -R 0755 /home/www && \
    
    #编译nginx
    apk add build-base pcre-dev openssl-dev zlib-dev && \
    wget https://github.com/msl4437/Danp/raw/main/src/nginx-$Nginx_VERSION.tar.gz && \
    tar zxf nginx-$Nginx_VERSION.tar.gz && \
    cd nginx-$Nginx_VERSION && \
    ./configure \
        --user=www \
        --group=www \
        --prefix=/usr/local/nginx \
        --error-log-path=/usr/local/nginx/logs/error.log \
        --http-log-path=/usr/local/nginx/logs/access.log \
        --pid-path=/usr/local/nginx/nginx.pid \
        --lock-path=/usr/local/nginx/nginx.lock \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-pcre && \
    make && \
    make install && \
    
    #编译apache
    cd - && \
    apk add build-base pcre-dev openssl-dev zlib-dev && \
    wget https://github.com/msl4437/Danp/raw/main/src/httpd-$Apache_VERSION.tar.gz && \
    tar -zxf httpd-$Apache_VERSION.tar.gz && \
    cd httpd-$Apache_VERSION && \
    wget https://github.com/msl4437/Danp/raw/main/src/apr-1.5.2.tar.gz && \
    wget https://github.com/msl4437/Danp/raw/main/src/apr-util-1.5.4.tar.gz && \
    tar -zxf apr-util-1.5.4.tar.gz && \
    tar -zxf apr-1.5.2.tar.gz && \
    cp -rf apr-1.5.2 srclib/apr && \
    cp -rf apr-util-1.5.4 srclib/apr-util && \
    ./configure \
        --prefix=/usr/local/apache \
        --enable-mods-shared=most \
        --enable-headers \
        --enable-mime-magic \
        --enable-proxy \
        --enable-so \
        --enable-rewrite \
        --enable-ssl \
        --with-ssl \
        --enable-deflate \
        --with-pcre \
        --with-included-apr \
        --with-apr-util \
        --enable-mpms-shared=all \
        --enable-remoteip && \
    make && \
    make install && \
    sed -i "s#logs/httpd.pid#httpd.pid#g" /usr/local/apache/conf/extra/httpd-mpm.conf && \
    
    #编译php
    cd - && \
    apk add perl-dev libxml2-dev sqlite-dev curl-dev libpng-dev libjpeg-turbo-dev freetype-dev gettext-dev libwebp-dev icu-dev oniguruma-dev libxslt-dev libzip-dev libsodium-dev && \
    sed -i "s#/replace/with/path/to/perl/interpreter#/usr/bin/perl#g" /usr/local/apache/bin/apxs && \
    wget https://github.com/msl4437/Danp/raw/main/src/php-$PHP_VERSION.tar.gz && \
    tar -zxf php-$PHP_VERSION.tar.gz && \
    cd php-$PHP_VERSION && \
    ./configure \
        --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --with-config-file-scan-dir=/usr/local/php/conf.d \
        --with-apxs2=/usr/local/apache/bin/apxs \
        --with-mhash \
        --with-openssl \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --enable-gd \
        --with-iconv \
        --with-zlib \
        --with-zip \
        --enable-inline-optimization \
        --disable-rpath \
        --enable-xml \
        --enable-bcmath \
        --enable-shmop \
        --enable-sysvsem \
        --enable-sysvshm \
        --enable-sysvmsg \
        --enable-mbregex \
        --enable-mbstring \
        --enable-ftp \
        --enable-pcntl \
        --enable-sockets \
        --with-xmlrpc \
        --enable-soap \
        --with-gettext \
        --with-curl \
        --with-jpeg \
        --with-freetype \
        --enable-opcache \
        --enable-intl \
        --with-xsl \
        --with-pear \
        --with-sodium \
        --with-mhash \
        --with-webp && \
    make && \
    make install && \
    
    #调整配置文件
    cd - && \
    wget https://github.com/msl4437/Danp/raw/main/src/config.tar.gz && \
    tar -zxf config.tar.gz && \
    chown -R www:www /usr/local/www && \
    chmod -R 0755 /usr/local/www && \
    
    echo -e '#!/bin/sh\n/usr/local/nginx/sbin/nginx -s stop\n/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf\n/usr/local/apache/bin/httpd -k restart\necho "Success!"' > /usr/local/bin/danp && \
    chmod +x /usr/local/bin/danp && \
    rm -rf config.tar.gz php-$PHP_VERSION.tar.gz php-$PHP_VERSION httpd-$Apache_VERSION.tar.gz httpd-$Apache_VERSION nginx-$Nginx_VERSION.tar.gz nginx-$Nginx_VERSION
    
# 开放22端口
EXPOSE 22 80 443

# 执行ssh启动命令
ENTRYPOINT ["/bin/sh", "entrypoint.sh"]
