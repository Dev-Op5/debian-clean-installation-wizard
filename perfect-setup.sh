#!/bin/bash
clear
##############
# Am I root? #
##############
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

#########################################
#Check whether the wget is exists or not#
#########################################
if [ ! -e '/usr/bin/wget' ]; then
    apt-get -y install wget
    if [ $? -ne 0 ]; then
        echo "Error: can't install wget"
        exit 1
    fi
fi
###########################################
#Check if the server has been setup before#
###########################################
install_summarize=/root/.setup_perfectly.txt
if [ -f $install_summarize ]; then
  clear
  cat $install_summarize
  exit 0
fi

echo ""
echo "********************************************************"
echo "   DEBIAN WHEEZY PERFECT APPLICATION SERVER INSTALLER   "
echo "    -- proudly present by eRQee (q@mokapedia.com) --    "
echo "********************************************************"
echo ""
echo "Enter the IP/Hostname Information"
echo "---------------------------------"
read -p "The Computer Name     : " serverinfo_hostname
read -p "Interface (eth0/eth1) : " serverinfo_eth
read -p "IP Address            : " serverinfo_ip
read -p "Subnet Mask           : " serverinfo_subnet
read -p "Default Gateway       : " serverinfo_gateway
read -p "DNS                   : " serverinfo_dns
echo ""

network_conf_file=/etc/network/interfaces
echo "auto lo" > $network_conf_file
echo "iface lo inet loopback" >> $network_conf_file
echo "" >> $network_conf_file
echo "# The primary network interface" >> $network_conf_file
echo "auto $serverinfo_eth" >> $network_conf_file
echo "allow-hotplug $serverinfo_eth" >> $network_conf_file
echo "iface eth0 inet static" >> $network_conf_file
echo "      address         $serverinfo_ip" >> $network_conf_file
echo "      netmask         $serverinfo_subnet" >> $network_conf_file
echo "      gateway         $serverinfo_gateway" >> $network_conf_file
echo "      dns-nameservers $serverinfo_dns" >> $network_conf_file

network_conf_file=/etc/resolv.conf
echo "domain mokapedia.net" > $network_conf_file
echo "search mokapedia.net" >> $network_conf_file
echo "nameserver $serverinfo_dns" > $network_conf_file

echo "$serverinfo_hostname" > /etc/hostname

network_conf_file=/etc/hosts
echo "127.0.0.1 localhost localhost.localdomain" > $network_conf_file
echo "127.0.1.1 $serverinfo_hostname" >> $network_conf_file
echo ""
echo ""
echo "Which Debian Repository do you prefer?"
echo "1. kambing.ui.ac.id"
echo "2. kartolo.sby.datautama.net.id"
echo ""
read -p "Your choice? (1/2) : " which_repo
echo ""
echo ""
echo "What kind of application server role do you want to apply?"
echo "1. Perfect Server for Nginx, PHP5-FPM, and MariaDB"
echo "2. Dedicated Nginx & PHP5-FPM Web Server only"
echo "3. Dedicated MariaDB Database Server only"
echo "4. Dedicated PostgreSQL Database Server only"
echo "5. Odoo8 Perfect Server"
read -p "Your Choice (1/2/3/4/5) : " appserver_type
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ]; then
  echo ""
  echo "Which MariaDB version you prefer?"
  echo "1. MariaDB 10.0.x"
  echo "2. MariaDB 10.1.x"
  echo ""
  read -p "Your Choice (1/2) : " mariadb_version
fi
if [ "$appserver_type" = '4' ]; then
  echo ""
  echo "Which PostgreSQL version you prefer?"
  echo "1. PostgreSQL 8.4"
  echo "2. PostgreSQL 9.2"
  echo "3. PostgreSQL 9.4"
  echo ""
  read -p "Your Choice (1/2/3) : " postgresql_version
fi
if [ "$appserver_type" = '2' ]; then
  echo ""
  echo "Which Database Client Libraries do you want to connect from PHP?"
  echo "1. MariaDB"
  echo "2. PostgreSQL"
  echo "3. Both"
  echo ""
  read -p "Your Choice (1/2/3) : " client_libraries_option
fi

if [ "$appserver_type" != '2' ]; then
  echo ""
  read -p "Enter the default database root password: " db_root_password
fi
  echo ""
  read -p "Git Identifier Username   : " git_user_name
  read -p "Git Identifier User Email : " git_user_email

echo ""
echo "-- starting the automated installer --"
echo ""


##############################
#rebuild the software sources#
##############################
repo=/etc/apt/sources.list
# choose preferred repository list
if [ -f /etc/apt/sources.list.old ]; then
  rm /etc/apt/sources.list.old
fi
mv $repo /etc/apt/sources.list.old && touch $repo

if [ "$which_repo" = '1' ]; then
  repo_src="kambing.ui.ac.id"
else
  repo_src="kartolo.sby.datautama.net.id"
fi

repo=/etc/apt/sources.list

# uncomment line below to force using kartolo.sby.datautama.net.id
# repo_src="kartolo.sby.datautama.net.id"

echo "deb http://$repo_src/debian/ wheezy main non-free contrib" >> $repo
echo "deb-src http://$repo_src/debian/ wheezy main non-free contrib" >> $repo
echo "deb http://$repo_src/debian-security/ wheezy/updates main non-free contrib" >> $repo
echo "deb-src http://$repo_src/debian-security/ wheezy/updates main non-free contrib" >> $repo
echo "deb http://$repo_src/debian/ wheezy-updates main non-free contrib" >> $repo
echo "deb-src http://$repo_src/debian/ wheezy-updates main non-free contrib" >> $repo
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ]; then
  echo "" >> $repo
  echo "deb http://nginx.org/packages/mainline/debian/ wheezy nginx" >> $repo
  echo "deb-src http://nginx.org/packages/mainline/debian/ wheezy nginx" >> $repo
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  echo "" >> $repo
  if [ "$mariadb_version" = '1' ]; then
    echo "deb http://mariadb.biz.net.id//repo/10.0/debian wheezy main" >> $repo
    echo "deb-src http://mariadb.biz.net.id//repo/10.0/debian wheezy main" >> $repo
  else
    echo "deb http://mariadb.biz.net.id//repo/10.1/debian wheezy main" >> $repo
    echo "deb-src http://mariadb.biz.net.id//repo/10.1/debian wheezy main" >> $repo
  fi
fi
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  echo "" >> $repo
  echo "deb http://kambing.ui.ac.id/postgresql/repos/apt/ wheezy-pgdg main" >> $repo
  echo "deb-src http://kambing.ui.ac.id/postgresql/repos/apt/ wheezy-pgdg main" >> $repo
fi
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2'  ] || [ "$appserver_type" = '5' ]; then
  echo "" >> $repo
  echo "deb http://$repo_src/dotdeb wheezy all" >> $repo
  echo "deb-src http://$repo_src/dotdeb wheezy all" >> $repo
  echo "deb http://$repo_src/dotdeb wheezy-php56 all" >> $repo
  echo "deb-src http://$repo_src/dotdeb wheezy-php56 all" >> $repo
fi
##############
#get GPG Keys#
##############
#dotdeb.org
wget --quiet -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -
#postgresql.org
wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
#nginx.org
wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
#mariadb.org
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db

######################
# performance tuning #
######################

echo "root soft nofile 65536" >> /etc/security/limits.conf
echo "root hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 10240    65535" >> /etc/sysctl.conf

############################
#update the repository list#
############################
dpkg-reconfigure locales
apt-get update -y && apt-get dist-upgrade -y && apt-get install -y --fix-missing bash-completion consolekit firmware-linux-free \
                                                                   gnupg-curl unzip libexpat1-dev gettext libz-dev \
                                                                   build-essential libssl-dev libgnutls-dev libcurl4-gnutls-dev

#\#######################
#install the newest git#
########################

if [ "$which_repo" = '2' ]; then
  apt-get install -y
  mkdir -p /tmp/git
  cd /tmp/git
  wget --no-check-certificate https://github.com/git/git/archive/master.zip
  unzip master.zip
  cd git-master
  make prefix=/usr/local all
  make prefix=/usr/local install
  ln -sf /usr/local/bin/git* /usr/bin
  cd /tmp
  rm -R /tmp/git
else
  apt-get install -y unzip git git-core build-essential
fi

###############
#configure git#
###############
ssh-keygen -t rsa -C "$git_user_email" -N "" -f /root/.ssh/id_rsa
git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"
git config --global core.editor nano
git config --global color.ui true

echo "alias sedot='wget --recursive --page-requisites --html-extension --convert-links --no-parent --random-wait -r -p -E -e robots=off'" >> /etc/bash.bashrc
echo "alias commit='git add --all . && git commit -m'" >> /etc/bash.bashrc
echo "alias push='git push -u origin master'" >> /etc/bash.bashrc
echo "alias pull='git pull origin master'" >> /etc/bash.bashrc

############################
#install essential packages#
############################
apt-get install -y sudo locate whois curl lynx openssl python perl libaio1 hdparm rsync traceroute imagemagick libmcrypt-dev \
                   python-software-properties pcregrep snmp-mibs-downloader tcpdump gawk checkinstall cdbs devscripts dh-make \
                   libxml-parser-perl check python-pip libbz2-dev libpcre3-dev libxml2-dev unixodbc-bin sysv-rc-conf uuid-dev \
                   libicu-dev libncurses5-dev libffi-dev debconf-utils libpng12-dev libjpeg-dev libgif-dev libevent-dev chrpath \
                   libfontconfig1-dev libxft-dev optipng g++ fakeroot ntp zip p7zip-full zlib1g-dev libyaml-dev libgdbm-dev \
                   libreadline-dev libxslt-dev ruby-full gperf bison g++ libsqlite3-dev libfreetype6 libpng-dev ttf-mscorefonts-installer \
		   xfonts-scalable poppler-utils libxrender-dev xfonts-base xfonts-75dpi fontconfig libxrender1 xfonts-75dpi xfonts-base
###############
#configure ntp#
###############
sed -i 's/debian.pool.ntp.org iburst/id.pool.ntp.org/g' /etc/ntp.conf
service ntp restart

################
#install nodejs#
################
curl -sL https://deb.nodesource.com/setup | bash -
apt-get install -y nodejs

###################
#install phantomjs#
###################
cd /tmp
wget http://src.mokapedia.net/linux-x64/phantomjs-1.9.7-linux-x86_64.tar.bz2
tar jxf phantomjs-1.9.7-linux-x86_64.tar.bz2
cp phantomjs-1.9.7-linux-x86_64/bin/phantomjs /usr/bin

############################
# install grunt bower gulp #
############################
echo prefix = ~/.node >> ~/.npmrc
echo 'export PATH=$HOME/.node/bin:$PATH' >> ~/.bashrc
echo 'export NODE_PATH=/usr/local/lib/node_modules' >> ~/.bashrc
echo 'export NODE_PATH=$NODE_PATH:/root/.node/lib/node_modules' >> ~/.bashrc
source ~/.bashrc
. ~/.bashrc

mkdir -p /root/.node
npm install -g grunt bower less
npm install yo gulp

##################
# install java-8 #
##################

echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo /usr/bin/debconf-set-selections
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
apt-get update -y && apt-get install -y oracle-java8-installer
apt-get install -y oracle-java8-set-default

#################################
#install (and configure) mariadb#
#################################

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  export DEBIAN_FRONTEND=noninteractive
  if [ "$mariadb_version" = '1' ]; then
    echo "mariadb-server-10.0 mysql-server/root_password password $db_root_password" | sudo /usr/bin/debconf-set-selections
    echo "mariadb-server-10.0 mysql-server/root_password_again password $db_root_password" | sudo /usr/bin/debconf-set-selections
    apt-get install -y mariadb-server-10.0 mariadb-client-10.0 libmariadbclient-dev mariadb-connect-engine-10.0 mariadb-oqgraph-engine-10.0 mariadb-test-10.0
  else
    echo "mariadb-server-10.1 mysql-server/root_password password $db_root_password" | sudo /usr/bin/debconf-set-selections
    echo "mariadb-server-10.1 mysql-server/root_password_again password $db_root_password" | sudo /usr/bin/debconf-set-selections
    apt-get install -y mariadb-server-10.1 mariadb-client-10.1 libmariadbclient-dev mariadb-connect-engine-10.1 mariadb-oqgraph-engine-10.1 mariadb-test-10.1
  fi

  # reconfigure my.cnf
  cd /tmp
  wget http://code.mokapedia.net/automagic/default-server-config/raw/master/my.cnf
  mv /etc/mysql/my.cnf /etc/mysql/my.cnf.original
  cp /tmp/my.cnf /etc/mysql/my.cnf

  # restart the services
  service mysql restart

  # install mysql udf
  cd /tmp
  wget http://src.mokapedia.net/others/lib_mysqludf_debian.tar.gz
  tar zxvf lib_mysqludf_debian.tar.gz
  cd /tmp/lib_mysqludf_debian
  cp bin/* /usr/lib/mysql/plugin
  mysql -uroot --password=$db_root_password < udf_initialize.sql

  # restart the services again
  service mysql restart
fi


##########################################
#install (and configure) nginx & php5-fpm#
##########################################
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ] || [ "$appserver_type" = '5' ]; then

  apt-get install -y nginx php5 php5-fpm php5-cgi php5-cli php5-common php5-curl php5-dbg php5-dev php5-enchant php5-gd \
                     php5-gmp php5-imap php5-ldap php5-mcrypt php5-mysqlnd php5-odbc php5-pgsql \
                     php5-pspell php5-readline php5-recode php5-sqlite php5-sybase php5-tidy php5-xmlrpc php5-xsl php-pear \
                     php5-geoip php5-mongo php5-imagick php-fpdf php5-apcu
  # install client libraries
  if [ "$appserver_type" = '1' ]; then
    # app_server_type is nginx/php5-fpm/mariadb
    apt-get install -y libmariadbclient-dev
  else
    if [ "$app_server_type" = '2' ]; then
      # app_server_type is dedicated nginx/php5-fpm
      if [ "$client_libraries_option" = '1' ]; then
        apt-get install -y libmariadbclient-dev
      fi
      if [ "$client_libraries_option" = '2' ]; then
        apt-get install -y libpq-dev
      fi
      if [ "$client_libraries_option" = '3' ]; then
        apt-get install -y libpq-dev libmariadbclient-dev
      fi
    fi
  fi

  # configuring nginx
  mkdir -p /etc/nginx/sites-enabled
  mkdir -p /tmp/config/
  cd /tmp/config
  wget http://code.mokapedia.net/automagic/default-server-config/raw/master/fastcgi_params
  mv /etc/nginx/fastcgi_params /etc/nginx/original.fastcgi_params
  cp fastcgi_params /etc/nginx/fastcgi_params

  wget http://code.mokapedia.net/automagic/default-server-config/raw/master/nginx.conf
  mv /etc/nginx/nginx.conf /etc/nginx/nginx.original.conf
  cp nginx.conf /etc/nginx/nginx.conf

  wget http://code.mokapedia.net/automagic/default-server-config/raw/master/security.conf
  cp security.conf /etc/nginx/security.conf

  # configuring php5-fpm
  mkdir -p /var/lib/php5/sessions
  mkdir -p /var/lib/php5/cookies
  chmod -R 777 /var/lib/php5/sessions
  chmod -R 777 /var/lib/php5/cookies
  cd /tmp/config

  wget http://code.mokapedia.net/automagic/default-server-config/raw/master/php.ini
  wget http://code.mokapedia.net/automagic/default-server-config/raw/master/www.conf

  mv /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini-original
  mv /etc/php5/cli/php.ini /etc/php5/cli/php.ini-original
  cp php.ini /etc/php5/fpm/php.ini
  cp php.ini /etc/php5/cli/php.ini
  mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf-original
  cp www.conf /etc/php5/fpm/pool.d/www.conf

  cd /tmp/config
  wget http://src.mokapedia.net/others/config/000default.conf
  cp 000default.conf /etc/nginx/sites-enabled/

  # restart the services
  service nginx restart && service php5-fpm restart

  # create the webroot workspaces
  mkdir -p /var/www
  chown -R www-data:www-data /var/www

  ########################
  # install composer.phar#
  ########################

  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer

  ### TODO
  ### - install premium maxmind geoip

fi

cd /tmp

#############################################
# install (and configure) postgresql (!TODO)#
#############################################
if [ "$appserver_type" = '4' ]; then
  postgresql_root_password=$db_root_password

  if [ $postgresql_version = '1' ] ; then
    apt-get install -y postgresql-8.4 postgresql-client-8.4 postgresql-contrib-8.4 libpq-dev
  fi
  if [ $postgresql_version = '2' ] ; then
    apt-get install -y postgresql-9.2 postgresql-client-9.2 postgresql-contrib-9.2 libpq-dev
  fi
  if [ $postgresql_version = '3' ] ; then
    apt-get install -y postgresql-9.4 postgresql-client-9.4 postgresql-contrib-9.4 libpq-dev
  fi
fi

#############################################
# install (and configure) odoo8 (!TODO)     #
#############################################

cd /tmp

if [ "$appserver_type" = '5' ]; then

  echo "--------------------------------"
  echo ""
  echo "INSTALLING odoo8........."
  echo ""
  echo "--------------------------------"
  adduser --system --home=/opt/odoo --group odoo
  postgresql_root_password=$db_root_password
  echo "PostgreSQL 9.4"
  apt-get install -y postgresql-9.4 postgresql-client-9.4 postgresql-contrib-9.4 libpq-dev
  echo "Create PostgreSQL User"
  sudo -u postgres -H createuser --createdb --username postgres --no-createrole --no-superuser odoo
  service postgresql start
  sudo -u postgres -H psql -c"ALTER user odoo WITH PASSWORD '$db_root_password'"
  service postgresql restart

  echo "Installing necessary python libraries"
  apt-get install -y python-cups python-dateutil python-decorator python-docutils python-feedparser \
		     python-gdata python-geoip python-gevent python-imaging python-jinja2 python-ldap python-libxslt1
		     python-lxml python-mako python-mock python-openid python-passlib python-psutil python-psycopg2
		     python-pybabel python-pychart python-pydot python-pyparsing python-pypdf python-reportlab python-requests \
		     python-simplejson python-tz python-unicodecsv python-unittest2 python-vatnumber python-vobject \
		     python-werkzeug python-xlwt python-yaml

  echo "Installing wkhtmltopdf"
  cd /tmp
  wget http://jaist.dl.sourceforge.net/project/wkhtmltopdf/0.12.2.1/wkhtmltox-0.12.2.1_linux-wheezy-amd64.deb
  dpkg -i wkhtmltox-0.12.2.1_linux-wheezy-amd64.deb
  ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  ln -s /usr/local/bin/wkhtmltoimage /usr/bin
  
  echo "Clone the Odoo 8.0 latest sources"
  cd /opt/odoo
  sudo -u odoo -H git clone https://www.github.com/odoo/odoo --depth 1 --branch 8.0 --single-branch .
  touch /etc/odoo-server.conf
  echo "[options]" > /etc/odoo-server.conf
  echo "; This is the password that allows database operations:" >> /etc/odoo-server.conf
  echo "; admin_passwd = admin" >> /etc/odoo-server.conf
  echo "db_host = False" >> /etc/odoo-server.conf
  echo "db_port = False" >> /etc/odoo-server.conf
  echo "db_user = odoo" >> /etc/odoo-server.conf
  echo "db_password = $db_root_password" >> /etc/odoo-server.conf
  echo "addons_path = /opt/odoo/addons" >> /etc/odoo-server.conf
  echo "logfile = /var/log/odoo/odoo-server.log" >> /etc/odoo-server.conf

  chown odoo: /etc/odoo-server.conf
  chmod 640 /etc/odoo-server.conf

  cd /tmp
  wget http://www.theopensourcerer.com/wp-content/uploads/2014/09/odoo-server
  cp /tmp/odoo-server /etc/init.d/odoo-server
  chmod 755 /etc/init.d/odoo-server
  chown root: /etc/init.d/odoo-server

  mkdir -p /var/log/odoo
  chown -R odoo:root /var/log/odoo
  chmod -R 777 /var/log/odoo

  update-rc.d odoo-server defaults

  /etc/init.d/odoo-server start

fi

#########################################################################
#flag the server that she's already setup perfectly (to avoid reinstall)#
#########################################################################
touch $install_summarize
timestamp_flag=` date +%F\ %H:%M:%S`
echo "*********************************************************" > $install_summarize
echo "   DEBIAN WHEEZY PERFECT APPLICATION SERVER INSTALLER    " >> $install_summarize
echo "    -- proudly present by eRQee (q@mokapedia.com) --     " >> $install_summarize
echo "                       *   *   *                         " >> $install_summarize
echo "                   INSTALL SUMMARIZE                     " >> $install_summarize
echo "*********************************************************" >> $install_summarize
echo "" >> $install_summarize
echo "Done installing at $timestamp_flag" >> $install_summarize
echo "Using repo http://$repo_src" >> $install_summarize
echo "" >> $install_summarize

nginx_ver=$(nginx -v)
php_ver=$(php -v | grep "(cli)")
mysql_ver=$(mysql --version)
pgsql_ver=$(psql --version)
git_ver=$(git --version)
node_ver=$(node -v)
npm_ver=$(npm -v)
phantomjs_ver=$(phantomjs -v)
grunt_ver=$(grunt --version)
bower_ver=$(bower --version)
gulp_ver=$(gulp --version | grep "CLI")
yeoman_ver=$(yeoman --version)

echo "[Web Server Information]"  >> $install_summarize
echo "$nginx_ver" >> $install_summarize
echo "$php_ver" >> $install_summarize
echo "" >> $install_summarize
echo "[MariaDB Information]" >> $install_summarize
echo "$mysql_ver" >> $install_summarize
echo "MariaDB root Password : $mariadb_root_password" >> $install_summarize
echo "" >> $install_summarize
echo "[PostgreSQL Information]" >> $install_summarize
echo "$pgsql_ver" >> $install_summarize
echo "PostgreSQL postgres Password : $postgresql_root_password" >> $install_summarize
echo "PostgreSQL odoo Password : $postgresql_odoo_password" >> $install_summarize
echo "" >> $install_summarize
echo "[Git Information]"  >> $install_summarize
echo "$git_ver" >> $install_summarize
git config --list >> $install_summarize 2>&1
echo "" >> $install_summarize
echo "[Web Dev Tools]"  >> $install_summarize
echo "$node_ver" >> $install_summarize
echo "$npm_ver" >> $install_summarize
echo "$phantomjs_ver" >> $install_summarize
echo "$grunt_ver" >> $install_summarize
echo "$bower_ver" >> $install_summarize
echo "$gulp_ver" >> $install_summarize
echo "$yeoman_ver" >> $install_summarize
echo "" >> $install_summarize
echo "*----------------------*" >> $install_summarize
echo "* This Server SSH Keys *" >> $install_summarize
echo "*----------------------*" >> $install_summarize
echo "please copy this into GitLab `deployer` (a.k.a. commit@codingaja.com) account" >> $install_summarize
echo "" >> $install_summarize
cat /root/.ssh/id_rsa.pub >> $install_summarize 2>&1
echo "" >> $install_summarize
echo "" >> $install_summarize
echo "********************************************************" >> $install_summarize
echo "                         ENJOY                          " >> $install_summarize
echo "********************************************************" >> $install_summarize
clear
cat $install_summarize
exit 0
