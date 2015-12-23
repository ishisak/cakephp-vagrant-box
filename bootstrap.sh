#!/bin/bash

function init() {
  local HAS_ALREADY_VAGRANT_UP="/tmp/has_already_vagrant_up"
  if [ -f ${HAS_ALREADY_VAGRANT_UP} ]; then return 0; fi
  cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
  sed -i 's/us.debian/jp.debian/g' /etc/apt/sources.list
  apt-get update
  export LANG="en_US.UTF-8"
  export LC_ALL=${LANG}
  sed -i 's/# ja_JP.UTF-8/ja_JP.UTF-8/g' /etc/locale.gen
  locale-gen --purge ${LANG}
  dpkg-reconfigure -f noninteractive locales && /usr/sbin/update-locale LANG=$LANG LC_ALL=$LANG
  touch ${HAS_ALREADY_VAGRANT_UP}
}

function vim() {
  if [ $(dpkg --get-selections | grep -c vim-gtk) -gt 0 ]; then return 0; fi
  apt-get install -y vim-gtk
}

function git() {
  local VERSION="2.4.0"
  local INSTALL_PATH="/usr/local/git"
  if [ -d ${INSTALL_PATH} ]; then return 0; fi
  mkdir -p ${INSTALL_PATH}/src && cd $_
  wget -O git-${VERSION}.tar.xz https://www.kernel.org/pub/software/scm/git/git-${VERSION}.tar.xz
  tar xf git-${VERSION}.tar.xz && rm git-${VERSION}.tar.xz
  mv git-${VERSION} ${VERSION}
  cd ${VERSION}
  apt-get install -y zlib1g-dev gettext libcurl4-openssl-dev
  ./configure --prefix=${INSTALL_PATH}/${VERSION}
  make && make install
  ln -s ${INSTALL_PATH}/${VERSION} ${INSTALL_PATH}/current
}

function zsh() {
  if [ $(dpkg --get-selections | grep -c zsh) -gt 0 ]; then return 0; fi
  apt-get install -y zsh
  chsh -s $(which zsh) root
}

function openssl() {
  local VERSION="1.0.2a"
  local INSTALL_PATH="/usr/local/openssl"
  if [ -d ${INSTALL_PATH} ]; then return 0; fi
  mkdir -p ${INSTALL_PATH}/src && cd $_
  wget -O openssl-${VERSION}.tar.gz https://www.openssl.org/source/openssl-1.0.2a.tar.gz
  tar xf openssl-${VERSION}.tar.gz && rm openssl-${VERSION}.tar.gz
  mv openssl-${VERSION} ${VERSION}
  cd ${VERSION}
  wget http://www.linuxfromscratch.org/patches/blfs/svn/openssl-${VERSION}-fix_parallel_build-2.patch
  patch -Np1 -i openssl-1.0.2a-fix_parallel_build-2.patch
  ./config --prefix=${INSTALL_PATH}/${VERSION}
  make && make install
  ln -s ${INSTALL_PATH}/${VERSION} ${INSTALL_PATH}/current
}

function mariadb() {
  local VERSION="10.1.4"
  local INSTALL_PATH="/usr/local/mariadb"
  if [ -d ${INSTALL_PATH} ]; then return 0; fi
  mkdir -p ${INSTALL_PATH}/src && cd $_
  wget -O mariadb-${VERSION}.tar.gz https://downloads.mariadb.com/files/MariaDB/mariadb-${VERSION}/source/mariadb-${VERSION}.tar.gz
  tar xf mariadb-${VERSION}.tar.gz && rm mariadb-${VERSION}.tar.gz
  mv mariadb-${VERSION} ${VERSION}
  cd ${VERSION}
  apt-get install -y cmake build-essential libncurses5-dev
  cmake . -DCMAKE_INSTALL_PREFIX=${INSTALL_PATH}/${VERSION}
  make && make install
  cp ${INSTALL_PATH}/src/${VERSION}/support-files/mysql.server /etc/init.d/mysql
  cp ${INSTALL_PATH}/src/${VERSION}/support-files/my-huge.cnf  /etc/my.cnf
  sed -i -e '42icharacter-set-server = utf8\' /etc/my.cnf
  ln -s ${INSTALL_PATH}/${VERSION} ${INSTALL_PATH}/current
  groupadd mysql
  useradd -r -g mysql mysql
  chown -R mysql:mysql ${INSTALL_PATH}
  cd ${INSTALL_PATH}/current
  ${INSTALL_PATH}/current/scripts/mysql_install_db --user=mysql
  chmod +x /etc/init.d/mysql
  update-rc.d mysql defaults
  systemctl start mysql
  local MARIADB_PATH="/usr/local/mariadb/current/bin"
  ${MARIADB_PATH}/mysql < /vagrant/setup_database.sql
  ${MARIADB_PATH}/mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -uroot mysql
}

function php() {
  local VERSION="5.6.8"
  local INSTALL_PATH="/usr/local/php"
  if [ -d ${INSTALL_PATH} ]; then return 0; fi
  mkdir -p ${INSTALL_PATH}/src && cd $_
  wget -O php-${VERSION}.tar.xz http://jp1.php.net/get/php-${VERSION}.tar.xz/from/this/mirror
  tar xf php-${VERSION}.tar.xz && rm php-${VERSION}.tar.xz
  mv php-${VERSION} ${VERSION}
  cd ${VERSION}
  apt-get install -y libxml2-dev libmcrypt-dev libicu-dev
  ./configure --prefix=${INSTALL_PATH}/${VERSION} \
              --enable-mbstring \
              --enable-fpm \
              --with-fpm-user=vagrant \
              --with-fpm-group=vagrant \
              --with-pdo-mysql=/usr/local/mariadb/current \
              --without-sqlite \
              --with-openssl=/usr/local/openssl/current \
              --with-mcrypt=/usr/include \
              --enable-zip \
              --enable-intl \
              --enable-bcmath \
              --with-config-file-path=${INSTALL_PATH}/${VERSION}/lib/php
  make && make install
  cp /vagrant/php.ini ${INSTALL_PATH}/${VERSION}/lib/php/php.ini
  cp ${INSTALL_PATH}/${VERSION}/etc/php-fpm.conf.default ${INSTALL_PATH}/${VERSION}/etc/php-fpm.conf
  cp ${INSTALL_PATH}/src/${VERSION}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
  chmod +x /etc/init.d/php-fpm
  update-rc.d php-fpm defaults
  systemctl start php-fpm
  ln -s ${INSTALL_PATH}/${VERSION} ${INSTALL_PATH}/current
}

function composer() {
  local INSTALL_PATH="/usr/local/bin/composer"
  if [ -f ${INSTALL_PATH} ]; then return 0; fi
  cd ${HOME}
  sudo apt-get install -y curl
  curl -kS https://getcomposer.org/installer | /usr/local/php/current/bin/php
  mv composer.phar ${INSTALL_PATH}
  # to fix openssl error
  cd /usr/lib/ssl/certs
  wget http://curl.haxx.se/ca/cacert.pem
  mv cacert.pem ca-bundle.crt
}

function phpcsfixer() {
  local INSTALL_PATH="/root/.composer/vendor/bin/php-cs-fixer"
  if [ -f ${INSTALL_PATH} ]; then return 0; fi
  /usr/local/bin/composer global require fabpot/php-cs-fixer
}

function xdebug() {
  local INSTALL_PATH="/usr/local/php/current/lib/php/extensions/no-debug-non-zts-20131226/xdebug.so"
  if [ -f ${INSTALL_PATH} ]; then return 0; fi
  apt-get install -y autoconf
  pecl install xdebug
}

function nginx() {
  local VERSION="1.9.0"
  local INSTALL_PATH="/usr/local/nginx"
  if [ -d ${INSTALL_PATH} ]; then return 0; fi
  mkdir -p ${INSTALL_PATH}/src && cd $_
  wget -O nginx-${VERSION}.tar.gz http://nginx.org/download/nginx-${VERSION}.tar.gz
  tar xf nginx-${VERSION}.tar.gz && rm nginx-${VERSION}.tar.gz
  mv nginx-${VERSION} ${VERSION}
  cd ${VERSION}
  apt-get install -y libpcre3 libpcre3-dev
  ./configure --prefix=${INSTALL_PATH}/${VERSION}
  make && make install
  cp /vagrant/nginx.conf ${INSTALL_PATH}/${VERSION}/conf/nginx.conf
  ln -s ${INSTALL_PATH}/${VERSION} ${INSTALL_PATH}/current
  ${GIT_PATH}/git clone --depth 1 https://github.com/Fleshgrinder/nginx-sysvinit-script.git
  sed -i 's/:\/bin/:\/bin:\/usr\/local\/nginx\/current\/sbin/g' ${INSTALL_PATH}/src/${VERSION}/nginx-sysvinit-script/init
  sed -i 's/PIDFILE=.*)/PIDFILE=\/usr\/local\/nginx\/current\/logs\/nginx.pid/g' ${INSTALL_PATH}/src/${VERSION}/nginx-sysvinit-script/init
  cd ${INSTALL_PATH}/src/${VERSION}/nginx-sysvinit-script && make && rm /etc/default/nginx

  local DOMAIN="my.cakephp.com"
  local WEBAPP_PATH="/var/www/${DOMAIN}"
  if [ -d ${WEBAPP_PATH}/logs ]; then return 0; fi
  mkdir ${WEBAPP_PATH}/logs
}

function cakephp() {
  local VERSION="3.0.3"
  local DOMAIN="my.cakephp.com"
  local WEBAPP_PATH="/var/www/${DOMAIN}"
  if [ -d ${WEBAPP_PATH}/cakephp-${VERSION} ]; then return 0; fi
  /usr/local/bin/composer create-project --prefer-dist cakephp/app /var/www/api.307house.com/cakephp-${VERSION}
  cd ${WEBAPP_PATH}
  ln -s cakephp-${VERSION} public
}

function flyway() {
  local VERSION="3.2.1"
  local INSTALL_PATH="/usr/local/flyway"
  if [ -d ${INSTALL_PATH} ]; then return 0; fi
  mkdir -p ${INSTALL_PATH} && cd $_
  wget -O flyway-${VERSION}.tar.gz https://bintray.com/artifact/download/business/maven/flyway-commandline-${VERSION}-linux-x64.tar.gz
  tar xf flyway-${VERSION}.tar.gz && rm flyway-${VERSION}.tar.gz
  mv flyway-${VERSION} ${VERSION}
  ln -s ${INSTALL_PATH}/${VERSION} ${INSTALL_PATH}/current
}

function ohmyzsh() {
  if [ -d ${HOME}/.oh-my-zsh ]; then return 0; fi
  cd ${HOME}
  ${GIT_PATH}/git clone git://github.com/robbyrussell/oh-my-zsh.git ${HOME}/.oh-my-zsh
}

init
vim
git
zsh
openssl
GIT_PATH="/usr/local/git/current/bin"
export PATH=${PATH}:${GIT_PATH}
mariadb
php
PHP_PATH="/usr/local/php/current/bin"
export PATH=${PATH}:${PHP_PATH}
composer
phpcsfixer
xdebug
nginx
cakephp
flyway

ohmyzsh
