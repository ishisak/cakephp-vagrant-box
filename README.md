# cakephp server box builded by vagrant.
This Vagrantfile is based on debian8.
Main worker is root, so please `sudo su` when you login this vm.

## requirement
* Vagrant
* VirtualBox

## how to
```
git clone https://github.com/ishisak/cakephp-vagrant-box.git
cd cakephp-vagrant-box
vagrant up

# nginx started before shared directory is mounted.
# So please restart nginx.
./start_up.sh
vagrant ssh
# access via browser
http://my.cakephp.com
# TODO you should setup database connection setting
# If you want to use git in this vm, please setup your name and e-mail.
```

## database info
Please see **setup_database.sh**.
All information is there.
This vm is installed **flyway** which is easy database migration tool.

## eash file description
+ *Vagrantfile*
  using vagrant up
+ *my.cakephp.com*
  this is webapp domain
 * *public*
   cakephp is here
 * *logs*
   nginx logs are here
+ *startup.sh*
  always running when vagrant up  
  nginx started before shared direcoty is mounted so added this shell script into Vagrantfile

## installed software info
name         |version|installed via
-------------|-------|-------------
git          |2.4.0  |source code  
vim-gtk      |7.4    |apt-get      
zsh          |5.0.7  |apt-get      
php          |5.6.8  |source code  
composer     |1.0-dev|source code  
openssl      |1.0.2a |source code  
nginx        |1.9.0  |source code  
cakephp      |3.0.3  |source code  
mariadb      |10.1.4 |source code  
flyway       |3.2.1  |download commandline tools
xdebug       |       |pecl
php-cs-fixer |       |composer

* installed direcoty
```
/usr/local/${software}/${version}
```
* symlink for latest version
```
/usr/local/${software}/current
```
* source code
```
/usr/local/${software}/src/${version}
```

## webapp info
* document root
```
/var/www/my.cakephp.com/public
```
* nginx logs
```
/var/www/my.cakephp.com/logs/access_log
/var/www/my.cakephp.com/logs/error_log
```
* setup your hosts
```
echo '192.168.33.10   my.cakephp.com' >> /etc/hosts
```

## development
Host machine mounts guest machine's webapp directory.
So you can edit your editor at host machine.
```
vim /path/to/my.cakephp.com/public/webroot/index.php
# some change and refresh your browser, you can find your changing.
```
And you can tail access and error log.
Like following command.
```
tail -f /path/to/my.cakephp.com/logs/*.log
```
You should format your code before remote push.
```
php-cs-fixer fix src --config=default
```

## Let's enjoy developing!
