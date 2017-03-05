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
echo "*************************************************************"
echo "   DEBIAN JESSIE 8.7+ PERFECT APPLICATION SERVER INSTALLER   "
echo "    -- proudly present by eRQee (q@codingaja.com) --    "
echo "*************************************************************"
echo ""
echo ""
echo "What kind of application server role do you want to apply?"
echo "1. Perfect Server for Nginx, PHP-FPM, and MariaDB"
echo "2. Dedicated Nginx & PHP-FPM Web Server only"
echo "3. Dedicated MariaDB Database Server only"
echo "4. Dedicated PostgreSQL Database Server only"
echo "5. Odoo Perfect Server"
read -p "Your Choice (1/2/3/4/5) : " appserver_type

if [ "$appserver_type" != '2' ]; then
  echo ""
  read -p "Enter the default database root password: " db_root_password
fi

echo ""
read -p "Git Identifier Username   : " git_user_name
read -p "Git Identifier User Email : " git_user_email

echo ""
read -p "Proceed to Install? (Y/N) : " lets_go

if [ "$lets_go" != 'Y' ]; then
  if [ "$lets_go" != 'y' ]; then
    exit 1
  fi
fi


##############################
#rebuild the software sources#
##############################
repo=/etc/apt/sources.list
# choose preferred repository list
if [ -f /etc/apt/sources.list.old ]; then
  rm /etc/apt/sources.list.old
fi
mv $repo /etc/apt/sources.list.old && touch $repo

repo=/etc/apt/sources.list

echo "deb http://kambing.ui.ac.id/debian/ jessie main non-free contrib" >> $repo
echo "deb-src http://kambing.ui.ac.id/debian/ jessie main non-free contrib" >> $repo
echo "deb http://kambing.ui.ac.id/debian/ jessie-updates main non-free contrib" >> $repo
echo "deb-src http://kambing.ui.ac.id/debian/ jessie-updates main non-free contrib" >> $repo
echo "deb http://kambing.ui.ac.id/debian-security/ jessie/updates main non-free contrib" >> $repo
echo "deb-src http://kambing.ui.ac.id/debian-security/ jessie/updates main non-free contrib" >> $repo

apt update && apt install -y apt-transport-https curl unzip zip lsb-release \
                             ca-certificates python-software-properties software-properties-common \
                             git git-core tcpdump traceroute libaio1 sudo locate

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2'  ] || [ "$appserver_type" = '5' ]; then
  #nginx
  echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" > /etc/apt/sources.list.d/nginx-mainline.list
  echo "deb-src http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list.d/nginx-mainline.list
  wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
  #php
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php-deb.sury.org.list
  wget --no-check-certificate --quiet -O - https://packages.sury.org/php/apt.gpg | apt-key add - 
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  echo "deb http://kartolo.sby.datautama.net.id/mariadb/repo/10.2/debian jessie main" > /etc/apt/sources.list.d/mariadb-10.2.list
  echo "deb-src http://kartolo.sby.datautama.net.id/mariadb/repo/10.2/debian jessie main" >> /etc/apt/sources.list.d/mariadb-10.2.list
  apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  echo "deb https://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main 9.6" > /etc/apt/sources.list.d/postgresql-9.6.list
  echo "deb-src https://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main 9.6" >> /etc/apt/sources.list.d/postgresql-9.6.list
  wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
fi

echo "" >> $repo

#redis
echo "deb http://kambing.ui.ac.id/dotdeb jessie all" >> /etc/apt/sources.list.d/redis-dotdeb.org.list
echo "deb-src http://kambing.ui.ac.id/dotdeb jessie all" >> /etc/apt/sources.list.d/redis-dotdeb.org.list
wget --quiet -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -

#mongodb
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb http://repo.mongodb.org/apt/debian "$(lsb_release -sc)"/mongodb-org/3.4 main" | sudo tee /etc/apt/sources.list.d/mongodb-3.4.list

#rabbitmq
echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/source.list.d/rabbitmq-server.list
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 6B73A36E6026DFCA
wget -O- -q https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | apt-key add -
wget -O- -q https://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add -

###########################################################
#Disable ipv6 : prevent errors while fetching the repo
###########################################################

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

apt update && apt upgrade -y

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
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf

############################
#update the repository list#
############################

dpkg --add-architecture i386
apt install -y bash-completion consolekit libexpat1-dev gettext \
               gnupg-curl unzip build-essential libssl-dev \
               libcurl4-gnutls-dev locales-all libz-dev

locale-gen en_US en_US.UTF-8 id_ID id_ID.UTF-8

###############
#configure git#
###############
ssh-keygen -t rsa -C "$git_user_email" -N "" -f /root/.ssh/id_rsa
git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"
git config --global core.editor nano
git config --global color.ui true

echo "" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc
echo "alias sedot='wget --recursive --page-requisites --html-extension --convert-links --no-parent --random-wait -r -p -E -e robots=off'" >> /etc/bash.bashrc
echo "alias commit='git add --all . && git commit -m'" >> /etc/bash.bashrc
echo "alias push='git push -u origin master'" >> /etc/bash.bashrc
echo "alias pull='git pull origin master'" >> /etc/bash.bashrc

############################
#install essential packages#
############################
apt install -y whois lynx openssl python perl libaio1 hdparm rsync imagemagick libmcrypt-dev \
               python-software-properties pcregrep gawk checkinstall cdbs devscripts dh-make \
               libxml-parser-perl check python-pip libbz2-dev libpcre3-dev libxml2-dev unixodbc-bin sysv-rc-conf uuid-dev \
               libicu-dev libncurses5-dev libffi-dev debconf-utils libpng12-dev libjpeg-dev libgif-dev libevent-dev chrpath \
               libfontconfig1-dev libxft-dev optipng g++ fakeroot zip p7zip-full zlib1g-dev libyaml-dev libgdbm-dev \
               libreadline-dev libxslt-dev ruby-full gperf bison g++ libsqlite3-dev libfreetype6 libpng-dev \
               xfonts-scalable poppler-utils libxrender-dev xfonts-base xfonts-75dpi fontconfig libxrender1 libldap2-dev \
               libsasl2-dev build-essential g++ flex bison gperf ruby perl libsqlite3-dev libfontconfig1-dev libicu-dev \
               libfreetype6 libssl-dev libpng-dev libjpeg-dev python libX11-dev libxext-dev

################
#install nodejs#
################
curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
apt install -y nodejs
npm install -g npm@latest grunt-cli bower gulp less less-plugin-clean-css generator-feathers graceful-fs@^4.0.0 yo minimatch@3.0.2

##################
# install java-8 #
##################

echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo /usr/bin/debconf-set-selections
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
apt update -y && apt install -y oracle-java8-installer && apt install -y oracle-java8-set-default

#################################
#install (and configure) mariadb#
#################################

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  export DEBIAN_FRONTEND=noninteractive
  echo "mariadb-server-10.2 mysql-server/root_password password $db_root_password" | sudo /usr/bin/debconf-set-selections
  echo "mariadb-server-10.2 mysql-server/root_password_again password $db_root_password" | sudo /usr/bin/debconf-set-selections
  apt install -y mariadb-server-10.2 mariadb-server-core-10.2 mariadb-client-10.2 mariadb-client-core-10.2 mariadb-connect-engine-10.2 \
                 mariadb-cracklib-password-check-10.2 mariadb-gssapi-server-10.2 mariadb-gssapi-client-10.2 mariadb-oqgraph-engine-10.2 \
                 mariadb-plugin-mroonga mariadb-plugin-spider

  # reconfigure my.cnf
  cd /tmp
  echo "" > my.cnf
  echo "# MariaDB database server configuration file." >> my.cnf
  echo "# Configured template by eRQee (q@codingaja.com)" >> my.cnf
  echo "# -------------------------------------------------------------------------------" >> my.cnf
  echo "" >> my.cnf
  echo "[client]" >> my.cnf
  echo "port                      = 3306" >> my.cnf
  echo "socket                    = /var/run/mysqld/mysqld.sock" >> my.cnf
  echo "default-character-set     = utf8" >> my.cnf
  echo "" >> my.cnf
  echo "[mysqld_safe]" >> my.cnf
  echo "socket                    = /var/run/mysqld/mysqld.sock" >> my.cnf
  echo "log_error                 = /var/log/mysql/mariadb.err" >> my.cnf
  echo "nice                      = 0" >> my.cnf
  echo "" >> my.cnf
  echo "[mysqldump]" >> my.cnf
  echo "quick" >> my.cnf
  echo "quote-names" >> my.cnf
  echo "max_allowed_packet        = 1024M" >> my.cnf
  echo "" >> my.cnf
  echo "[mysql]" >> my.cnf
  echo "socket                    = /var/run/mysqld/mysqld.sock" >> my.cnf
  echo "no-auto-rehash  " >> my.cnf
  echo "local-infile" >> my.cnf
  echo "" >> my.cnf
  echo "[isamchk]" >> my.cnf
  echo "key_buffer                = 16M" >> my.cnf
  echo "" >> my.cnf
  echo "[mysqld]" >> my.cnf
  echo "# ------------------------------------------------------------------------------- : SERVER PROFILE" >> my.cnf
  echo "server_id                 = 1" >> my.cnf
  echo "bind-address              = 127.0.0.1" >> my.cnf
  echo "port                      = 3306" >> my.cnf
  echo "socket                    = /var/run/mysqld/mysqld.sock" >> my.cnf
  echo "pid-file                  = /var/run/mysqld/mysqld.pid" >> my.cnf
  echo "user                      = mysql" >> my.cnf
  echo "sql_mode                  = NO_ENGINE_SUBSTITUTION,TRADITIONAL" >> my.cnf
  echo "" >> my.cnf
  echo "# ------------------------------------------------------------------------------- : PATH" >> my.cnf
  echo "basedir                   = /usr" >> my.cnf
  echo "datadir                   = /var/lib/mysql" >> my.cnf
  echo "tmpdir                    = /tmp" >> my.cnf
  echo "#general_log_file         = /var/log/mysql/mysql.log" >> my.cnf
  echo "log_bin                   = /var/log/mysql/mariadb-bin" >> my.cnf
  echo "log_bin_index             = /var/log/mysql/mariadb-bin.index" >> my.cnf
  echo "slow_query_log_file       = /var/log/mysql/mariadb-slow.log" >> my.cnf
  echo "#relay_log                = /var/log/mysql/relay-bin" >> my.cnf
  echo "#relay_log_index          = /var/log/mysql/relay-bin.index" >> my.cnf
  echo "#relay_log_info_file      = /var/log/mysql/relay-bin.info" >> my.cnf
  echo "" >> my.cnf
  echo "# ------------------------------------------------------------------------------- : LOCALE SETTING" >> my.cnf
  echo "lc_messages_dir           = /usr/share/mysql" >> my.cnf
  echo "lc_messages               = en_US" >> my.cnf
  echo "init_connect              = 'SET collation_connection=utf8_unicode_ci; SET NAMES utf8;'" >> my.cnf
  echo "character_set_server      = utf8" >> my.cnf
  echo "collation_server          = utf8_unicode_ci" >> my.cnf
  echo "character-set-server      = utf8" >> my.cnf
  echo "collation-server          = utf8_unicode_ci" >> my.cnf
  echo "skip-character-set-client-handshake" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : GENERIC FEATURES" >> my.cnf
  echo "big_tables                = 1" >> my.cnf
  echo "event_scheduler           = 1" >> my.cnf
  echo "lower_case_table_names    = 1" >> my.cnf
  echo "performance_schema        = 0" >> my.cnf
  echo "group_concat_max_len      = 184467440737095475" >> my.cnf
  echo "skip-external-locking     = 1" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : CONNECTION SETTING" >> my.cnf
  echo "max_connections           = 100" >> my.cnf
  echo "max_connect_errors        = 9999" >> my.cnf
  echo "connect_timeout           = 60" >> my.cnf
  echo "wait_timeout              = 600" >> my.cnf
  echo "interactive_timeout       = 600" >> my.cnf
  echo "max_allowed_packet        = 128M" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : CACHE SETTING" >> my.cnf
  echo "thread_cache_size         = 128" >> my.cnf
  echo "sort_buffer_size          = 4M" >> my.cnf
  echo "bulk_insert_buffer_size   = 64M" >> my.cnf
  echo "tmp_table_size            = 256M" >> my.cnf
  echo "max_heap_table_size       = 256M" >> my.cnf
  echo "query_cache_limit         = 128K    ## default: 128K" >> my.cnf
  echo "query_cache_size          = 64    ## default: 64M" >> my.cnf
  echo "query_cache_type          = DEMAND  ## for more write intensive setups, set to DEMAND or OFF" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Logging" >> my.cnf
  echo "general_log               = 0" >> my.cnf
  echo "log_warnings              = 2" >> my.cnf
  echo "slow_query_log            = 0" >> my.cnf
  echo "long_query_time           = 10" >> my.cnf
  echo "#log_slow_rate_limit      = 1000" >> my.cnf
  echo "log_slow_verbosity        = query_plan" >> my.cnf
  echo "#log-queries-not-using-indexes" >> my.cnf
  echo "#log_slow_admin_statements" >> my.cnf
  echo "log_bin_trust_function_creators = 1" >> my.cnf
  echo "#sync_binlog              = 1" >> my.cnf
  echo "expire_logs_days          = 10" >> my.cnf
  echo "max_binlog_size           = 100M" >> my.cnf
  echo "#log_slave_updates" >> my.cnf
  echo "#read_only" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : InnoDB" >> my.cnf
  echo "default_storage_engine    = InnoDB" >> my.cnf
  echo "#innodb_log_file_size     = 50M     ## you can't just change log file size, requires special procedure" >> my.cnf
  echo "innodb_buffer_pool_size   = 384M" >> my.cnf
  echo "innodb_log_buffer_size    = 8M" >> my.cnf
  echo "innodb_file_per_table     = 1" >> my.cnf
  echo "innodb_open_files         = 400" >> my.cnf
  echo "innodb_io_capacity        = 400" >> my.cnf
  echo "innodb_flush_method       = O_DIRECT" >> my.cnf
  echo "innodb_autoinc_lock_mode  = 2" >> my.cnf
  echo "innodb_doublewrite        = 1" >> my.cnf
  echo "innodb_flush_log_at_trx_commit  = 0" >> my.cnf
  echo "#innodb_autoinc_lock_mode = 2" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : MyISAM" >> my.cnf
  echo "myisam_recover            = BACKUP" >> my.cnf
  echo "key_buffer_size           = 128M" >> my.cnf
  echo "open-files-limit          = 4000" >> my.cnf
  echo "table_open_cache          = 400" >> my.cnf
  echo "myisam_sort_buffer_size   = 512M" >> my.cnf
  echo "concurrent_insert         = 2" >> my.cnf
  echo "read_buffer_size          = 2M" >> my.cnf
  echo "read_rnd_buffer_size      = 1M" >> my.cnf
  echo "" >> my.cnf
  echo "#auto_increment_increment = 2" >> my.cnf
  echo "#auto_increment_offset    = 1" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Galera Replication" >> my.cnf
  echo "#report_host              = master1" >> my.cnf
  echo "#sync_binlog              = 1   ## not fab for performance, but safer" >> my.cnf
  echo "binlog-format             = ROW" >> my.cnf
  echo "max_binlog_size           = 100M" >> my.cnf
  echo "expire_logs_days          = 10" >> my.cnf
  echo "#wsrep_on                 = ON" >> my.cnf
  echo "#wsrep_provider           =" >> my.cnf
  echo "#wsrep_cluster_address    =" >> my.cnf
  echo "#wsrep_slave_threads      = 1" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Security Features" >> my.cnf
  echo "# chroot                  = /var/lib/mysql/" >> my.cnf
  echo "# ssl-ca                  = /etc/mysql/cacert.pem" >> my.cnf
  echo "# ssl-cert                = /etc/mysql/server-cert.pem" >> my.cnf
  echo "# ssl-key                 = /etc/mysql/server-key.pem" >> my.cnf
  echo "" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Extended Config" >> my.cnf
  echo "!includedir /etc/mysql/conf.d/" >> my.cnf

  mv /etc/mysql/my.cnf /etc/mysql/my.cnf.original
  cp /tmp/my.cnf /etc/mysql/my.cnf

  # restart the services
  service mysql restart

fi


##########################################
#install (and configure) nginx & php-fpm#
##########################################
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ] || [ "$appserver_type" = '5' ]; then
 
  apt install -y php7.1 php7.1-bcmath php7.1-bz2 php7.1-cgi php7.1-cli php7.1-common php7.1-curl \
                 php7.1-dba php7.1-dev php7.1-enchant php7.1-fpm php7.1-gd php7.1-gmp php7.1-imap \
                 php7.1-interbase php7.1-intl php7.1-json php7.1-ldap php7.1-mbstring php7.1-mcrypt \
                 php7.1-mysql php7.1-odbc php7.1-opcache php7.1-pgsql php7.1-pspell php7.1-readline \
                 php7.1-recode php7.1-snmp php7.1-soap php7.1-sqlite3 php7.1-sybase php7.1-tidy \
                 php7.1-xml php7.1-xmlrpc php7.1-xsl php7.1-zip php-mongodb php-geoip libgeoip-dev \
                 snmp-mibs-downloader nginx

  if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '5' ]; then
    apt install -y libmariadbclient-dev
  fi
  
  if [ "$appserver_type" = '5' ]; then
    apt install -y libpq-dev
  fi

  # configuring nginx
  mkdir -p /etc/nginx/sites-enabled

  cd /tmp
  echo "" > /tmp/fastcgi_params
  echo "fastcgi_param  QUERY_STRING       \$query_string;" >> /tmp/fastcgi_params
  echo "fastcgi_param  REQUEST_METHOD     \$request_method;" >> /tmp/fastcgi_params
  echo "fastcgi_param  CONTENT_TYPE       \$content_type;" >> /tmp/fastcgi_params
  echo "fastcgi_param  CONTENT_LENGTH     \$content_length;" >> /tmp/fastcgi_params
  echo "" >> /tmp/fastcgi_params
  echo "fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;" >> /tmp/fastcgi_params
  echo "fastcgi_param  REQUEST_URI        \$request_uri;" >> /tmp/fastcgi_params
  echo "fastcgi_param  DOCUMENT_URI       \$document_uri;" >> /tmp/fastcgi_params
  echo "fastcgi_param  DOCUMENT_ROOT      \$document_root;" >> /tmp/fastcgi_params
  echo "fastcgi_param  SERVER_PROTOCOL    \$server_protocol;" >> /tmp/fastcgi_params
  echo "fastcgi_param  REQUEST_SCHEME     \$scheme;" >> /tmp/fastcgi_params
  echo "fastcgi_param  SCRIPT_FILENAME    \$document_root$fastcgi_script_name;" >> /tmp/fastcgi_params
  echo "fastcgi_param  PATH_INFO          \$fastcgi_path_info;" >> /tmp/fastcgi_params
  echo "fastcgi_param  PATH_TRANSLATED    \$document_root$fastcgi_path_info;" >> /tmp/fastcgi_params
  echo "fastcgi_param  HTTPS              \$https if_not_empty;" >> /tmp/fastcgi_params
  echo "" >> /tmp/fastcgi_params
  echo "fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;" >> /tmp/fastcgi_params
  echo "fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;" >> /tmp/fastcgi_params
  echo "" >> /tmp/fastcgi_params
  echo "fastcgi_param  REMOTE_ADDR        \$remote_addr;" >> /tmp/fastcgi_params
  echo "fastcgi_param  REMOTE_PORT        \$remote_port;" >> /tmp/fastcgi_params
  echo "fastcgi_param  SERVER_ADDR        \$server_addr;" >> /tmp/fastcgi_params
  echo "fastcgi_param  SERVER_PORT        \$server_port;" >> /tmp/fastcgi_params
  echo "fastcgi_param  SERVER_NAME        \$server_name;" >> /tmp/fastcgi_params
  echo "" >> /tmp/fastcgi_params
  echo "" >> /tmp/fastcgi_params
  echo "# PHP only, required if PHP was built with --enable-force-cgi-redirect" >> /tmp/fastcgi_params
  echo "fastcgi_param  REDIRECT_STATUS    200;" >> /tmp/fastcgi_params

  rm /etc/nginx/fastcgi_params
  cp /tmp/fastcgi_params /etc/nginx

  cd /tmp
  echo "" > /tmp/nginx.conf
  echo "##-------------------------------------------##" >> /tmp/nginx.conf
  echo "# Last Update 1 March 2017 10:11 WIB by eRQee #" >> /tmp/nginx.conf
  echo "##-------------------------------------------##" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "user                    www-data;" >> /tmp/nginx.conf
  echo "pid                     /var/run/nginx.pid;" >> /tmp/nginx.conf
  echo "worker_processes        4;" >> /tmp/nginx.conf
  echo "error_log               /dev/null warn;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "events {" >> /tmp/nginx.conf
  echo "    worker_connections  1024;" >> /tmp/nginx.conf
  echo "}" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "http {" >> /tmp/nginx.conf
  echo "    include       /etc/nginx/mime.types;" >> /tmp/nginx.conf
  echo "    default_type  application/octet-stream;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    log_format  main '\$status \$time_local \$remote_addr \$body_bytes_sent \"\$request\" \"\$http_referer\" \"\$http_user_agent\" \"\$http_x_forwarded_for\"';" >> /tmp/nginx.conf
  echo "    log_format  gzip '\$status \$time_local \$remote_addr \$body_bytes_sent \"\$request\" \"\$http_referer\" \"\$http_user_agent\" \"\$http_x_forwarded_for\" \"\$gzip_ratio\"';" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    access_log  /dev/null  gzip;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    sendfile              on;" >> /tmp/nginx.conf
  echo "    tcp_nopush            on;" >> /tmp/nginx.conf
  echo "    tcp_nodelay           on;" >> /tmp/nginx.conf
  echo "    keepalive_timeout     65;" >> /tmp/nginx.conf
  echo "    types_hash_max_size   2048;" >> /tmp/nginx.conf
  echo "    server_tokens         off;" >> /tmp/nginx.conf
  echo "    server_names_hash_bucket_size       512;" >> /tmp/nginx.conf
  echo "    server_name_in_redirect             off;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    gzip                  on;" >> /tmp/nginx.conf
  echo "    gzip_disable          \"msie6\";" >> /tmp/nginx.conf
  echo "    gzip_vary             on;" >> /tmp/nginx.conf
  echo "    gzip_proxied          any;" >> /tmp/nginx.conf
  echo "    gzip_comp_level       6;" >> /tmp/nginx.conf
  echo "    gzip_buffers          16 8k;" >> /tmp/nginx.conf
  echo "    gzip_http_version     1.1;" >> /tmp/nginx.conf
  echo "    gzip_types            text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    proxy_connect_timeout 1200;" >> /tmp/nginx.conf
  echo "    proxy_send_timeout    1200;" >> /tmp/nginx.conf
  echo "    proxy_read_timeout    1200;" >> /tmp/nginx.conf
  echo "    send_timeout          1200;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    client_max_body_size  100M;" >> /tmp/nginx.conf
  echo "    client_header_timeout 3000;" >> /tmp/nginx.conf
  echo "    client_body_timeout   3000;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    fastcgi_read_timeout  3000;" >> /tmp/nginx.conf
  echo "    fastcgi_buffer_size   32k;" >> /tmp/nginx.conf
  echo "    fastcgi_buffers       8 16k;  # up to 1k + 128 * 1k" >> /tmp/nginx.conf
  echo "    fastcgi_max_temp_file_size 0;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    #upstream apache    { server 127.0.0.1:82; }" >> /tmp/nginx.conf
  echo "    #upstream odoo      { server 127.0.0.1:8069; }" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    include /etc/nginx/sites-enabled/*;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "}" >> /tmp/nginx.conf

  mv /etc/nginx/nginx.conf /etc/nginx/nginx.original.conf
  cp /tmp/nginx.conf /etc/nginx/nginx.conf

  cd /tmp
  echo "" > /tmp/security.conf
  echo '## Only requests to our Host are allowed' >> /tmp/security.conf
  echo '# if ($host !~ ^($server_name)$ ) { return 444; }' >> /tmp/security.conf
  echo '## Only allow these request methods' >> /tmp/security.conf
  echo 'if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE|OPTIONS)$ ) { return 444; }' >> /tmp/security.conf
  echo '## Deny certain Referers' >> /tmp/security.conf
  echo 'if ( $http_referer ~* (babes|love|nudit|poker|porn|sex) )  { return 404; return 403; }' >> /tmp/security.conf
  echo '## Cache the static contents' >> /tmp/security.conf
  echo 'location ~* ^.+.(jpg|jpeg|gif|png|ico|svg|woff|woff2|ttf|eot|txt|swf|mp4|ogg|flv|mp3|wav|mid|mkv|avi|3gp)$ { access_log off; expires max; }' >> /tmp/security.conf

  cp security.conf /etc/nginx/security.conf

  # configuring php7-fpm
  mkdir -p /var/lib/php/7.1/sessions
  chmod -R 777 /var/lib/php/7.1/sessions
  
  cd /tmp
  echo '' > /tmp/php.ini
  echo '[PHP]' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; About php.ini   ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; PHP"s initialization file, generally called php.ini, is responsible for' >> /tmp/php.ini
  echo '; configuring many of the aspects of PHP"s behavior.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; PHP attempts to find and load this configuration from a number of locations.' >> /tmp/php.ini
  echo '; The following is a summary of its search order:' >> /tmp/php.ini
  echo '; 1. SAPI module specific location.' >> /tmp/php.ini
  echo '; 2. The PHPRC environment variable. (As of PHP 5.2.0)' >> /tmp/php.ini
  echo '; 3. A number of predefined registry keys on Windows (As of PHP 5.2.0)' >> /tmp/php.ini
  echo '; 4. Current working directory (except CLI)' >> /tmp/php.ini
  echo '; 5. The web server"s directory (for SAPI modules), or directory of PHP' >> /tmp/php.ini
  echo '; (otherwise in Windows)' >> /tmp/php.ini
  echo '; 6. The directory from the --with-config-file-path compile time option, or the' >> /tmp/php.ini
  echo '; Windows directory (C:\windows or C:\winnt)' >> /tmp/php.ini
  echo '; See the PHP docs for more specific information.' >> /tmp/php.ini
  echo '; http://php.net/configuration.file' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The syntax of the file is extremely simple.  Whitespace and lines' >> /tmp/php.ini
  echo '; beginning with a semicolon are silently ignored (as you probably guessed).' >> /tmp/php.ini
  echo '; Section headers (e.g. [Foo]) are also silently ignored, even though' >> /tmp/php.ini
  echo '; they might mean something in the future.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Directives following the section heading [PATH=/www/mysite] only' >> /tmp/php.ini
  echo '; apply to PHP files in the /www/mysite directory.  Directives' >> /tmp/php.ini
  echo '; following the section heading [HOST=www.example.com] only apply to' >> /tmp/php.ini
  echo '; PHP files served from www.example.com.  Directives set in these' >> /tmp/php.ini
  echo '; special sections cannot be overridden by user-defined INI files or' >> /tmp/php.ini
  echo '; at runtime. Currently, [PATH=] and [HOST=] sections only work under' >> /tmp/php.ini
  echo '; CGI/FastCGI.' >> /tmp/php.ini
  echo '; http://php.net/ini.sections' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Directives are specified using the following syntax:' >> /tmp/php.ini
  echo '; directive = value' >> /tmp/php.ini
  echo '; Directive names are *case sensitive* - foo=bar is different from FOO=bar.' >> /tmp/php.ini
  echo '; Directives are variables used to configure PHP or PHP extensions.' >> /tmp/php.ini
  echo '; There is no name validation.  If PHP can"t find an expected' >> /tmp/php.ini
  echo '; directive because it is not set or is mistyped, a default value will be used.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The value can be a string, a number, a PHP constant (e.g. E_ALL or M_PI), one' >> /tmp/php.ini
  echo '; of the INI constants (On, Off, True, False, Yes, No and None) or an expression' >> /tmp/php.ini
  echo '; (e.g. E_ALL & ~E_NOTICE), a quoted string ("bar"), or a reference to a' >> /tmp/php.ini
  echo '; previously set variable or directive (e.g. ${foo})' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Expressions in the INI file are limited to bitwise operators and parentheses:' >> /tmp/php.ini
  echo '; |  bitwise OR' >> /tmp/php.ini
  echo '; ^  bitwise XOR' >> /tmp/php.ini
  echo '; &  bitwise AND' >> /tmp/php.ini
  echo '; ~  bitwise NOT' >> /tmp/php.ini
  echo '; !  boolean NOT' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Boolean flags can be turned on using the values 1, On, True or Yes.' >> /tmp/php.ini
  echo '; They can be turned off using the values 0, Off, False or No.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; An empty string can be denoted by simply not writing anything after the equal' >> /tmp/php.ini
  echo '; sign, or by using the None keyword:' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';  foo =         ; sets foo to an empty string' >> /tmp/php.ini
  echo ';  foo = None    ; sets foo to an empty string' >> /tmp/php.ini
  echo ';  foo = "None"  ; sets foo to the string "None"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If you use constants in your value, and these constants belong to a' >> /tmp/php.ini
  echo '; dynamically loaded extension (either a PHP extension or a Zend extension),' >> /tmp/php.ini
  echo '; you may only use these constants *after* the line that loads the extension.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; About this file ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; PHP comes packaged with two INI files. One that is recommended to be used' >> /tmp/php.ini
  echo '; in production environments and one that is recommended to be used in' >> /tmp/php.ini
  echo '; development environments.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; php.ini-production contains settings which hold security, performance and' >> /tmp/php.ini
  echo '; best practices at its core. But please be aware, these settings may break' >> /tmp/php.ini
  echo '; compatibility with older or less security conscience applications. We' >> /tmp/php.ini
  echo '; recommending using the production ini in production and testing environments.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; php.ini-development is very similar to its production variant, except it is' >> /tmp/php.ini
  echo '; much more verbose when it comes to errors. We recommend using the' >> /tmp/php.ini
  echo '; development version only in development environments, as errors shown to' >> /tmp/php.ini
  echo '; application users can inadvertently leak otherwise secure information.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This is php.ini-production INI file.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Quick Reference ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; The following are all the settings which are different in either the production' >> /tmp/php.ini
  echo '; or development versions of the INIs with respect to PHP"s default behavior.' >> /tmp/php.ini
  echo '; Please see the actual settings later in the document for more details as to why' >> /tmp/php.ini
  echo '; we recommend these changes in PHP"s behavior.' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; display_errors' >> /tmp/php.ini
  echo ';   Default Value: On' >> /tmp/php.ini
  echo ';   Development Value: On' >> /tmp/php.ini
  echo ';   Production Value: Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; display_startup_errors' >> /tmp/php.ini
  echo ';   Default Value: Off' >> /tmp/php.ini
  echo ';   Development Value: On' >> /tmp/php.ini
  echo ';   Production Value: Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; error_reporting' >> /tmp/php.ini
  echo ';   Default Value: E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED' >> /tmp/php.ini
  echo ';   Development Value: E_ALL' >> /tmp/php.ini
  echo ';   Production Value: E_ALL & ~E_DEPRECATED & ~E_STRICT' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; html_errors' >> /tmp/php.ini
  echo ';   Default Value: On' >> /tmp/php.ini
  echo ';   Development Value: On' >> /tmp/php.ini
  echo ';   Production value: On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; log_errors' >> /tmp/php.ini
  echo ';   Default Value: Off' >> /tmp/php.ini
  echo ';   Development Value: On' >> /tmp/php.ini
  echo ';   Production Value: On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; max_input_time' >> /tmp/php.ini
  echo ';   Default Value: -1 (Unlimited)' >> /tmp/php.ini
  echo ';   Development Value: 60 (60 seconds)' >> /tmp/php.ini
  echo ';   Production Value: 60 (60 seconds)' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; output_buffering' >> /tmp/php.ini
  echo ';   Default Value: Off' >> /tmp/php.ini
  echo ';   Development Value: 4096' >> /tmp/php.ini
  echo ';   Production Value: 4096' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; register_argc_argv' >> /tmp/php.ini
  echo ';   Default Value: On' >> /tmp/php.ini
  echo ';   Development Value: Off' >> /tmp/php.ini
  echo ';   Production Value: Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; request_order' >> /tmp/php.ini
  echo ';   Default Value: None' >> /tmp/php.ini
  echo ';   Development Value: "GP"' >> /tmp/php.ini
  echo ';   Production Value: "GP"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; session.gc_divisor' >> /tmp/php.ini
  echo ';   Default Value: 100' >> /tmp/php.ini
  echo ';   Development Value: 1000' >> /tmp/php.ini
  echo ';   Production Value: 1000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; session.sid_bits_per_character' >> /tmp/php.ini
  echo ';   Default Value: 4' >> /tmp/php.ini
  echo ';   Development Value: 5' >> /tmp/php.ini
  echo ';   Production Value: 5' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; short_open_tag' >> /tmp/php.ini
  echo ';   Default Value: On' >> /tmp/php.ini
  echo ';   Development Value: Off' >> /tmp/php.ini
  echo ';   Production Value: Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; track_errors' >> /tmp/php.ini
  echo ';   Default Value: Off' >> /tmp/php.ini
  echo ';   Development Value: On' >> /tmp/php.ini
  echo ';   Production Value: Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; variables_order' >> /tmp/php.ini
  echo ';   Default Value: "EGPCS"' >> /tmp/php.ini
  echo ';   Development Value: "GPCS"' >> /tmp/php.ini
  echo ';   Production Value: "GPCS"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; php.ini Options  ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Name for user-defined php.ini (.htaccess) files. Default is ".user.ini"' >> /tmp/php.ini
  echo ';user_ini.filename = ".user.ini"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; To disable this feature set this option to empty value' >> /tmp/php.ini
  echo ';user_ini.filename =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; TTL for user-defined php.ini files (time-to-live) in seconds. Default is 300 seconds (5 minutes)' >> /tmp/php.ini
  echo ';user_ini.cache_ttl = 300' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Language Options ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enable the PHP scripting language engine under Apache.' >> /tmp/php.ini
  echo '; http://php.net/engine' >> /tmp/php.ini
  echo 'engine = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive determines whether or not PHP will recognize code between' >> /tmp/php.ini
  echo '; <? and ?> tags as PHP source which should be processed as such. It is' >> /tmp/php.ini
  echo '; generally recommended that <?php and ?> should be used and that this feature' >> /tmp/php.ini
  echo '; should be disabled, as enabling it may result in issues when generating XML' >> /tmp/php.ini
  echo '; documents, however this remains supported for backward compatibility reasons.' >> /tmp/php.ini
  echo '; Note that this directive does not control the <?= shorthand tag, which can be' >> /tmp/php.ini
  echo '; used regardless of this directive.' >> /tmp/php.ini
  echo '; Default Value: On' >> /tmp/php.ini
  echo '; Development Value: Off' >> /tmp/php.ini
  echo '; Production Value: Off' >> /tmp/php.ini
  echo '; http://php.net/short-open-tag' >> /tmp/php.ini
  echo 'short_open_tag = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The number of significant digits displayed in floating point numbers.' >> /tmp/php.ini
  echo '; http://php.net/precision' >> /tmp/php.ini
  echo 'precision = 14' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Output buffering is a mechanism for controlling how much output data' >> /tmp/php.ini
  echo '; (excluding headers and cookies) PHP should keep internally before pushing that' >> /tmp/php.ini
  echo '; data to the client. If your application"s output exceeds this setting, PHP' >> /tmp/php.ini
  echo '; will send that data in chunks of roughly the size you specify.' >> /tmp/php.ini
  echo '; Turning on this setting and managing its maximum buffer size can yield some' >> /tmp/php.ini
  echo '; interesting side-effects depending on your application and web server.' >> /tmp/php.ini
  echo '; You may be able to send headers and cookies after you"ve already sent output' >> /tmp/php.ini
  echo '; through print or echo. You also may see performance benefits if your server is' >> /tmp/php.ini
  echo '; emitting less packets due to buffered output versus PHP streaming the output' >> /tmp/php.ini
  echo '; as it gets it. On production servers, 4096 bytes is a good setting for performance' >> /tmp/php.ini
  echo '; reasons.' >> /tmp/php.ini
  echo '; Note: Output buffering can also be controlled via Output Buffering Control' >> /tmp/php.ini
  echo ';   functions.' >> /tmp/php.ini
  echo '; Possible Values:' >> /tmp/php.ini
  echo ';   On = Enabled and buffer is unlimited. (Use with caution)' >> /tmp/php.ini
  echo ';   Off = Disabled' >> /tmp/php.ini
  echo ';   Integer = Enables the buffer and sets its maximum size in bytes.' >> /tmp/php.ini
  echo '; Note: This directive is hardcoded to Off for the CLI SAPI' >> /tmp/php.ini
  echo '; Default Value: Off' >> /tmp/php.ini
  echo '; Development Value: 4096' >> /tmp/php.ini
  echo '; Production Value: 4096' >> /tmp/php.ini
  echo '; http://php.net/output-buffering' >> /tmp/php.ini
  echo 'output_buffering = 4096' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; You can redirect all of the output of your scripts to a function.  For' >> /tmp/php.ini
  echo '; example, if you set output_handler to "mb_output_handler", character' >> /tmp/php.ini
  echo '; encoding will be transparently converted to the specified encoding.' >> /tmp/php.ini
  echo '; Setting any output handler automatically turns on output buffering.' >> /tmp/php.ini
  echo '; Note: People who wrote portable scripts should not depend on this ini' >> /tmp/php.ini
  echo ';   directive. Instead, explicitly set the output handler using ob_start().' >> /tmp/php.ini
  echo ';   Using this ini directive may cause problems unless you know what script' >> /tmp/php.ini
  echo ';   is doing.' >> /tmp/php.ini
  echo '; Note: You cannot use both "mb_output_handler" with "ob_iconv_handler"' >> /tmp/php.ini
  echo ';   and you cannot use both "ob_gzhandler" and "zlib.output_compression".' >> /tmp/php.ini
  echo '; Note: output_handler must be empty if this is set "On" !!!!' >> /tmp/php.ini
  echo ';   Instead you must use zlib.output_handler.' >> /tmp/php.ini
  echo '; http://php.net/output-handler' >> /tmp/php.ini
  echo ';output_handler =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; URL rewriter function rewrites URL on the fly by using' >> /tmp/php.ini
  echo '; output buffer. You can set target tags by this configuration.' >> /tmp/php.ini
  echo '; "form" tag is special tag. It will add hidden input tag to pass values.' >> /tmp/php.ini
  echo '; Refer to session.trans_sid_tags for usage.' >> /tmp/php.ini
  echo '; Default Value: "form="' >> /tmp/php.ini
  echo '; Development Value: "form="' >> /tmp/php.ini
  echo '; Production Value: "form="' >> /tmp/php.ini
  echo ';url_rewriter.tags' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; URL rewriter will not rewrites absolute URL nor form by default. To enable' >> /tmp/php.ini
  echo '; absolute URL rewrite, allowed hosts must be defined at RUNTIME.' >> /tmp/php.ini
  echo '; Refer to session.trans_sid_hosts for more details.' >> /tmp/php.ini
  echo '; Default Value: ""' >> /tmp/php.ini
  echo '; Development Value: ""' >> /tmp/php.ini
  echo '; Production Value: ""' >> /tmp/php.ini
  echo ';url_rewriter.hosts' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Transparent output compression using the zlib library' >> /tmp/php.ini
  echo '; Valid values for this option are "off", "on", or a specific buffer size' >> /tmp/php.ini
  echo '; to be used for compression (default is 4KB)' >> /tmp/php.ini
  echo '; Note: Resulting chunk size may vary due to nature of compression. PHP' >> /tmp/php.ini
  echo ';   outputs chunks that are few hundreds bytes each as a result of' >> /tmp/php.ini
  echo ';   compression. If you prefer a larger chunk size for better' >> /tmp/php.ini
  echo ';   performance, enable output_buffering in addition.' >> /tmp/php.ini
  echo '; Note: You need to use zlib.output_handler instead of the standard' >> /tmp/php.ini
  echo ';   output_handler, or otherwise the output will be corrupted.' >> /tmp/php.ini
  echo '; http://php.net/zlib.output-compression' >> /tmp/php.ini
  echo 'zlib.output_compression = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/zlib.output-compression-level' >> /tmp/php.ini
  echo ';zlib.output_compression_level = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; You cannot specify additional output handlers if zlib.output_compression' >> /tmp/php.ini
  echo '; is activated here. This setting does the same as output_handler but in' >> /tmp/php.ini
  echo '; a different order.' >> /tmp/php.ini
  echo '; http://php.net/zlib.output-handler' >> /tmp/php.ini
  echo ';zlib.output_handler =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Implicit flush tells PHP to tell the output layer to flush itself' >> /tmp/php.ini
  echo '; automatically after every output block.  This is equivalent to calling the' >> /tmp/php.ini
  echo '; PHP function flush() after each and every call to print() or echo() and each' >> /tmp/php.ini
  echo '; and every HTML block.  Turning this option on has serious performance' >> /tmp/php.ini
  echo '; implications and is generally recommended for debugging purposes only.' >> /tmp/php.ini
  echo '; http://php.net/implicit-flush' >> /tmp/php.ini
  echo '; Note: This directive is hardcoded to On for the CLI SAPI' >> /tmp/php.ini
  echo 'implicit_flush = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The unserialize callback function will be called (with the undefined class"' >> /tmp/php.ini
  echo '; name as parameter), if the unserializer finds an undefined class' >> /tmp/php.ini
  echo '; which should be instantiated. A warning appears if the specified function is' >> /tmp/php.ini
  echo '; not defined, or if the function doesn"t include/implement the missing class.' >> /tmp/php.ini
  echo '; So only set this entry, if you really want to implement such a' >> /tmp/php.ini
  echo '; callback-function.' >> /tmp/php.ini
  echo 'unserialize_callback_func =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; When floats & doubles are serialized store serialize_precision significant' >> /tmp/php.ini
  echo '; digits after the floating point. The default value ensures that when floats' >> /tmp/php.ini
  echo '; are decoded with unserialize, the data will remain the same.' >> /tmp/php.ini
  echo '; The value is also used for json_encode when encoding double values.' >> /tmp/php.ini
  echo '; If -1 is used, then dtoa mode 0 is used which automatically select the best' >> /tmp/php.ini
  echo '; precision.' >> /tmp/php.ini
  echo 'serialize_precision = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; open_basedir, if set, limits all file operations to the defined directory' >> /tmp/php.ini
  echo '; and below.  This directive makes most sense if used in a per-directory' >> /tmp/php.ini
  echo '; or per-virtualhost web server configuration file.' >> /tmp/php.ini
  echo '; http://php.net/open-basedir' >> /tmp/php.ini
  echo ';open_basedir =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive allows you to disable certain functions for security reasons.' >> /tmp/php.ini
  echo '; It receives a comma-delimited list of function names.' >> /tmp/php.ini
  echo '; http://php.net/disable-functions' >> /tmp/php.ini
  echo 'disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive allows you to disable certain classes for security reasons.' >> /tmp/php.ini
  echo '; It receives a comma-delimited list of class names.' >> /tmp/php.ini
  echo '; http://php.net/disable-classes' >> /tmp/php.ini
  echo 'disable_classes =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Colors for Syntax Highlighting mode.  Anything that"s acceptable in' >> /tmp/php.ini
  echo '; <span style="color: ???????"> would work.' >> /tmp/php.ini
  echo '; http://php.net/syntax-highlighting' >> /tmp/php.ini
  echo ';highlight.string  = #DD0000' >> /tmp/php.ini
  echo ';highlight.comment = #FF9900' >> /tmp/php.ini
  echo ';highlight.keyword = #007700' >> /tmp/php.ini
  echo ';highlight.default = #0000BB' >> /tmp/php.ini
  echo ';highlight.html    = #000000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If enabled, the request will be allowed to complete even if the user aborts' >> /tmp/php.ini
  echo '; the request. Consider enabling it if executing long requests, which may end up' >> /tmp/php.ini
  echo '; being interrupted by the user or a browser timing out. PHP"s default behavior' >> /tmp/php.ini
  echo '; is to disable this feature.' >> /tmp/php.ini
  echo '; http://php.net/ignore-user-abort' >> /tmp/php.ini
  echo ';ignore_user_abort = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Determines the size of the realpath cache to be used by PHP. This value should' >> /tmp/php.ini
  echo '; be increased on systems where PHP opens many files to reflect the quantity of' >> /tmp/php.ini
  echo '; the file operations performed.' >> /tmp/php.ini
  echo '; http://php.net/realpath-cache-size' >> /tmp/php.ini
  echo ';realpath_cache_size = 4096k' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Duration of time, in seconds for which to cache realpath information for a given' >> /tmp/php.ini
  echo '; file or directory. For systems with rarely changing files, consider increasing this' >> /tmp/php.ini
  echo '; value.' >> /tmp/php.ini
  echo '; http://php.net/realpath-cache-ttl' >> /tmp/php.ini
  echo ';realpath_cache_ttl = 120' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enables or disables the circular reference collector.' >> /tmp/php.ini
  echo '; http://php.net/zend.enable-gc' >> /tmp/php.ini
  echo 'zend.enable_gc = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If enabled, scripts may be written in encodings that are incompatible with' >> /tmp/php.ini
  echo '; the scanner.  CP936, Big5, CP949 and Shift_JIS are the examples of such' >> /tmp/php.ini
  echo '; encodings.  To use this feature, mbstring extension must be enabled.' >> /tmp/php.ini
  echo '; Default: Off' >> /tmp/php.ini
  echo ';zend.multibyte = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Allows to set the default encoding for the scripts.  This value will be used' >> /tmp/php.ini
  echo '; unless "declare(encoding=...)" directive appears at the top of the script.' >> /tmp/php.ini
  echo '; Only affects if zend.multibyte is set.' >> /tmp/php.ini
  echo '; Default: ""' >> /tmp/php.ini
  echo ';zend.script_encoding =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Miscellaneous ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Decides whether PHP may expose the fact that it is installed on the server' >> /tmp/php.ini
  echo '; (e.g. by adding its signature to the Web server header).  It is no security' >> /tmp/php.ini
  echo '; threat in any way, but it makes it possible to determine whether you use PHP' >> /tmp/php.ini
  echo '; on your server or not.' >> /tmp/php.ini
  echo '; http://php.net/expose-php' >> /tmp/php.ini
  echo 'expose_php = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Resource Limits ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum execution time of each script, in seconds' >> /tmp/php.ini
  echo '; http://php.net/max-execution-time' >> /tmp/php.ini
  echo '; Note: This directive is hardcoded to 0 for the CLI SAPI' >> /tmp/php.ini
  echo 'max_execution_time = 30' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum amount of time each script may spend parsing request data. It"s a good' >> /tmp/php.ini
  echo '; idea to limit this time on productions servers in order to eliminate unexpectedly' >> /tmp/php.ini
  echo '; long running scripts.' >> /tmp/php.ini
  echo '; Note: This directive is hardcoded to -1 for the CLI SAPI' >> /tmp/php.ini
  echo '; Default Value: -1 (Unlimited)' >> /tmp/php.ini
  echo '; Development Value: 60 (60 seconds)' >> /tmp/php.ini
  echo '; Production Value: 60 (60 seconds)' >> /tmp/php.ini
  echo '; http://php.net/max-input-time' >> /tmp/php.ini
  echo 'max_input_time = 60' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum input variable nesting level' >> /tmp/php.ini
  echo '; http://php.net/max-input-nesting-level' >> /tmp/php.ini
  echo ';max_input_nesting_level = 64' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; How many GET/POST/COOKIE input variables may be accepted' >> /tmp/php.ini
  echo '; max_input_vars = 1000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum amount of memory a script may consume (128MB)' >> /tmp/php.ini
  echo '; http://php.net/memory-limit' >> /tmp/php.ini
  echo 'memory_limit = 128M' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Error handling and logging ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive informs PHP of which errors, warnings and notices you would like' >> /tmp/php.ini
  echo '; it to take action for. The recommended way of setting values for this' >> /tmp/php.ini
  echo '; directive is through the use of the error level constants and bitwise' >> /tmp/php.ini
  echo '; operators. The error level constants are below here for convenience as well as' >> /tmp/php.ini
  echo '; some common settings and their meanings.' >> /tmp/php.ini
  echo '; By default, PHP is set to take action on all errors, notices and warnings EXCEPT' >> /tmp/php.ini
  echo '; those related to E_NOTICE and E_STRICT, which together cover best practices and' >> /tmp/php.ini
  echo '; recommended coding standards in PHP. For performance reasons, this is the' >> /tmp/php.ini
  echo '; recommend error reporting setting. Your production server shouldn"t be wasting' >> /tmp/php.ini
  echo '; resources complaining about best practices and coding standards. That"s what' >> /tmp/php.ini
  echo '; development servers and development settings are for.' >> /tmp/php.ini
  echo '; Note: The php.ini-development file has this setting as E_ALL. This' >> /tmp/php.ini
  echo '; means it pretty much reports everything which is exactly what you want during' >> /tmp/php.ini
  echo '; development and early testing.' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; Error Level Constants:' >> /tmp/php.ini
  echo '; E_ALL             - All errors and warnings (includes E_STRICT as of PHP 5.4.0)' >> /tmp/php.ini
  echo '; E_ERROR           - fatal run-time errors' >> /tmp/php.ini
  echo '; E_RECOVERABLE_ERROR  - almost fatal run-time errors' >> /tmp/php.ini
  echo '; E_WARNING         - run-time warnings (non-fatal errors)' >> /tmp/php.ini
  echo '; E_PARSE           - compile-time parse errors' >> /tmp/php.ini
  echo '; E_NOTICE          - run-time notices (these are warnings which often result' >> /tmp/php.ini
  echo ';                     from a bug in your code, but it"s possible that it was' >> /tmp/php.ini
  echo ';                     intentional (e.g., using an uninitialized variable and' >> /tmp/php.ini
  echo ';                     relying on the fact it is automatically initialized to an' >> /tmp/php.ini
  echo ';                     empty string)' >> /tmp/php.ini
  echo '; E_STRICT          - run-time notices, enable to have PHP suggest changes' >> /tmp/php.ini
  echo ';                     to your code which will ensure the best interoperability' >> /tmp/php.ini
  echo ';                     and forward compatibility of your code' >> /tmp/php.ini
  echo '; E_CORE_ERROR      - fatal errors that occur during PHP"s initial startup' >> /tmp/php.ini
  echo '; E_CORE_WARNING    - warnings (non-fatal errors) that occur during PHP"s' >> /tmp/php.ini
  echo ';                     initial startup' >> /tmp/php.ini
  echo '; E_COMPILE_ERROR   - fatal compile-time errors' >> /tmp/php.ini
  echo '; E_COMPILE_WARNING - compile-time warnings (non-fatal errors)' >> /tmp/php.ini
  echo '; E_USER_ERROR      - user-generated error message' >> /tmp/php.ini
  echo '; E_USER_WARNING    - user-generated warning message' >> /tmp/php.ini
  echo '; E_USER_NOTICE     - user-generated notice message' >> /tmp/php.ini
  echo '; E_DEPRECATED      - warn about code that will not work in future versions' >> /tmp/php.ini
  echo ';                     of PHP' >> /tmp/php.ini
  echo '; E_USER_DEPRECATED - user-generated deprecation warnings' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; Common Values:' >> /tmp/php.ini
  echo ';   E_ALL (Show all errors, warnings and notices including coding standards.)' >> /tmp/php.ini
  echo ';   E_ALL & ~E_NOTICE  (Show all errors, except for notices)' >> /tmp/php.ini
  echo ';   E_ALL & ~E_NOTICE & ~E_STRICT  (Show all errors, except for notices and coding standards warnings.)' >> /tmp/php.ini
  echo ';   E_COMPILE_ERROR|E_RECOVERABLE_ERROR|E_ERROR|E_CORE_ERROR  (Show only errors)' >> /tmp/php.ini
  echo '; Default Value: E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED' >> /tmp/php.ini
  echo '; Development Value: E_ALL' >> /tmp/php.ini
  echo '; Production Value: E_ALL & ~E_DEPRECATED & ~E_STRICT' >> /tmp/php.ini
  echo '; http://php.net/error-reporting' >> /tmp/php.ini
  echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive controls whether or not and where PHP will output errors,' >> /tmp/php.ini
  echo '; notices and warnings too. Error output is very useful during development, but' >> /tmp/php.ini
  echo '; it could be very dangerous in production environments. Depending on the code' >> /tmp/php.ini
  echo '; which is triggering the error, sensitive information could potentially leak' >> /tmp/php.ini
  echo '; out of your application such as database usernames and passwords or worse.' >> /tmp/php.ini
  echo '; For production environments, we recommend logging errors rather than' >> /tmp/php.ini
  echo '; sending them to STDOUT.' >> /tmp/php.ini
  echo '; Possible Values:' >> /tmp/php.ini
  echo ';   Off = Do not display any errors' >> /tmp/php.ini
  echo ';   stderr = Display errors to STDERR (affects only CGI/CLI binaries!)' >> /tmp/php.ini
  echo ';   On or stdout = Display errors to STDOUT' >> /tmp/php.ini
  echo '; Default Value: On' >> /tmp/php.ini
  echo '; Development Value: On' >> /tmp/php.ini
  echo '; Production Value: Off' >> /tmp/php.ini
  echo '; http://php.net/display-errors' >> /tmp/php.ini
  echo 'display_errors = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The display of errors which occur during PHP"s startup sequence are handled' >> /tmp/php.ini
  echo '; separately from display_errors. PHP"s default behavior is to suppress those' >> /tmp/php.ini
  echo '; errors from clients. Turning the display of startup errors on can be useful in' >> /tmp/php.ini
  echo '; debugging configuration problems. We strongly recommend you' >> /tmp/php.ini
  echo '; set this to "off" for production servers.' >> /tmp/php.ini
  echo '; Default Value: Off' >> /tmp/php.ini
  echo '; Development Value: On' >> /tmp/php.ini
  echo '; Production Value: Off' >> /tmp/php.ini
  echo '; http://php.net/display-startup-errors' >> /tmp/php.ini
  echo 'display_startup_errors = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Besides displaying errors, PHP can also log errors to locations such as a' >> /tmp/php.ini
  echo '; server-specific log, STDERR, or a location specified by the error_log' >> /tmp/php.ini
  echo '; directive found below. While errors should not be displayed on productions' >> /tmp/php.ini
  echo '; servers they should still be monitored and logging is a great way to do that.' >> /tmp/php.ini
  echo '; Default Value: Off' >> /tmp/php.ini
  echo '; Development Value: On' >> /tmp/php.ini
  echo '; Production Value: On' >> /tmp/php.ini
  echo '; http://php.net/log-errors' >> /tmp/php.ini
  echo 'log_errors = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Set maximum length of log_errors. In error_log information about the source is' >> /tmp/php.ini
  echo '; added. The default is 1024 and 0 allows to not apply any maximum length at all.' >> /tmp/php.ini
  echo '; http://php.net/log-errors-max-len' >> /tmp/php.ini
  echo 'log_errors_max_len = 1024' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Do not log repeated messages. Repeated errors must occur in same file on same' >> /tmp/php.ini
  echo '; line unless ignore_repeated_source is set true.' >> /tmp/php.ini
  echo '; http://php.net/ignore-repeated-errors' >> /tmp/php.ini
  echo 'ignore_repeated_errors = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Ignore source of message when ignoring repeated messages. When this setting' >> /tmp/php.ini
  echo '; is On you will not log errors with repeated messages from different files or' >> /tmp/php.ini
  echo '; source lines.' >> /tmp/php.ini
  echo '; http://php.net/ignore-repeated-source' >> /tmp/php.ini
  echo 'ignore_repeated_source = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If this parameter is set to Off, then memory leaks will not be shown (on' >> /tmp/php.ini
  echo '; stdout or in the log). This has only effect in a debug compile, and if' >> /tmp/php.ini
  echo '; error reporting includes E_WARNING in the allowed list' >> /tmp/php.ini
  echo '; http://php.net/report-memleaks' >> /tmp/php.ini
  echo 'report_memleaks = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This setting is on by default.' >> /tmp/php.ini
  echo ';report_zend_debug = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Store the last error/warning message in $php_errormsg (boolean). Setting this value' >> /tmp/php.ini
  echo '; to On can assist in debugging and is appropriate for development servers. It should' >> /tmp/php.ini
  echo '; however be disabled on production servers.' >> /tmp/php.ini
  echo '; Default Value: Off' >> /tmp/php.ini
  echo '; Development Value: On' >> /tmp/php.ini
  echo '; Production Value: Off' >> /tmp/php.ini
  echo '; http://php.net/track-errors' >> /tmp/php.ini
  echo 'track_errors = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Turn off normal error reporting and emit XML-RPC error XML' >> /tmp/php.ini
  echo '; http://php.net/xmlrpc-errors' >> /tmp/php.ini
  echo ';xmlrpc_errors = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; An XML-RPC faultCode' >> /tmp/php.ini
  echo ';xmlrpc_error_number = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; When PHP displays or logs an error, it has the capability of formatting the' >> /tmp/php.ini
  echo '; error message as HTML for easier reading. This directive controls whether' >> /tmp/php.ini
  echo '; the error message is formatted as HTML or not.' >> /tmp/php.ini
  echo '; Note: This directive is hardcoded to Off for the CLI SAPI' >> /tmp/php.ini
  echo '; Default Value: On' >> /tmp/php.ini
  echo '; Development Value: On' >> /tmp/php.ini
  echo '; Production value: On' >> /tmp/php.ini
  echo '; http://php.net/html-errors' >> /tmp/php.ini
  echo 'html_errors = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If html_errors is set to On *and* docref_root is not empty, then PHP' >> /tmp/php.ini
  echo '; produces clickable error messages that direct to a page describing the error' >> /tmp/php.ini
  echo '; or function causing the error in detail.' >> /tmp/php.ini
  echo '; You can download a copy of the PHP manual from http://php.net/docs' >> /tmp/php.ini
  echo '; and change docref_root to the base URL of your local copy including the' >> /tmp/php.ini
  echo '; leading "/". You must also specify the file extension being used including' >> /tmp/php.ini
  echo '; the dot. PHP"s default behavior is to leave these settings empty, in which' >> /tmp/php.ini
  echo '; case no links to documentation are generated.' >> /tmp/php.ini
  echo '; Note: Never use this feature for production boxes.' >> /tmp/php.ini
  echo '; http://php.net/docref-root' >> /tmp/php.ini
  echo '; Examples' >> /tmp/php.ini
  echo ';docref_root = "/phpmanual/"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/docref-ext' >> /tmp/php.ini
  echo ';docref_ext = .html' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; String to output before an error message. PHP"s default behavior is to leave' >> /tmp/php.ini
  echo '; this setting blank.' >> /tmp/php.ini
  echo '; http://php.net/error-prepend-string' >> /tmp/php.ini
  echo '; Example:' >> /tmp/php.ini
  echo ';error_prepend_string = "<span style="color: #ff0000">"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; String to output after an error message. PHP"s default behavior is to leave' >> /tmp/php.ini
  echo '; this setting blank.' >> /tmp/php.ini
  echo '; http://php.net/error-append-string' >> /tmp/php.ini
  echo '; Example:' >> /tmp/php.ini
  echo ';error_append_string = "</span>"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Log errors to specified file. PHP"s default behavior is to leave this value' >> /tmp/php.ini
  echo '; empty.' >> /tmp/php.ini
  echo '; http://php.net/error-log' >> /tmp/php.ini
  echo '; Example:' >> /tmp/php.ini
  echo ';error_log = php_errors.log' >> /tmp/php.ini
  echo '; Log errors to syslog (Event Log on Windows).' >> /tmp/php.ini
  echo ';error_log = syslog' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';windows.show_crt_warning' >> /tmp/php.ini
  echo '; Default value: 0' >> /tmp/php.ini
  echo '; Development value: 0' >> /tmp/php.ini
  echo '; Production value: 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Data Handling ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The separator used in PHP generated URLs to separate arguments.' >> /tmp/php.ini
  echo '; PHP"s default setting is "&".' >> /tmp/php.ini
  echo '; http://php.net/arg-separator.output' >> /tmp/php.ini
  echo '; Example:' >> /tmp/php.ini
  echo ';arg_separator.output = "&amp;"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; List of separator(s) used by PHP to parse input URLs into variables.' >> /tmp/php.ini
  echo '; PHP"s default setting is "&".' >> /tmp/php.ini
  echo '; NOTE: Every character in this directive is considered as separator!' >> /tmp/php.ini
  echo '; http://php.net/arg-separator.input' >> /tmp/php.ini
  echo '; Example:' >> /tmp/php.ini
  echo ';arg_separator.input = ";&"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive determines which super global arrays are registered when PHP' >> /tmp/php.ini
  echo '; starts up. G,P,C,E & S are abbreviations for the following respective super' >> /tmp/php.ini
  echo '; globals: GET, POST, COOKIE, ENV and SERVER. There is a performance penalty' >> /tmp/php.ini
  echo '; paid for the registration of these arrays and because ENV is not as commonly' >> /tmp/php.ini
  echo '; used as the others, ENV is not recommended on productions servers. You' >> /tmp/php.ini
  echo '; can still get access to the environment variables through getenv() should you' >> /tmp/php.ini
  echo '; need to.' >> /tmp/php.ini
  echo '; Default Value: "EGPCS"' >> /tmp/php.ini
  echo '; Development Value: "GPCS"' >> /tmp/php.ini
  echo '; Production Value: "GPCS";' >> /tmp/php.ini
  echo '; http://php.net/variables-order' >> /tmp/php.ini
  echo 'variables_order = "GPCS"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive determines which super global data (G,P & C) should be' >> /tmp/php.ini
  echo '; registered into the super global array REQUEST. If so, it also determines' >> /tmp/php.ini
  echo '; the order in which that data is registered. The values for this directive' >> /tmp/php.ini
  echo '; are specified in the same manner as the variables_order directive,' >> /tmp/php.ini
  echo '; EXCEPT one. Leaving this value empty will cause PHP to use the value set' >> /tmp/php.ini
  echo '; in the variables_order directive. It does not mean it will leave the super' >> /tmp/php.ini
  echo '; globals array REQUEST empty.' >> /tmp/php.ini
  echo '; Default Value: None' >> /tmp/php.ini
  echo '; Development Value: "GP"' >> /tmp/php.ini
  echo '; Production Value: "GP"' >> /tmp/php.ini
  echo '; http://php.net/request-order' >> /tmp/php.ini
  echo 'request_order = "GP"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive determines whether PHP registers $argv & $argc each time it' >> /tmp/php.ini
  echo '; runs. $argv contains an array of all the arguments passed to PHP when a script' >> /tmp/php.ini
  echo '; is invoked. $argc contains an integer representing the number of arguments' >> /tmp/php.ini
  echo '; that were passed when the script was invoked. These arrays are extremely' >> /tmp/php.ini
  echo '; useful when running scripts from the command line. When this directive is' >> /tmp/php.ini
  echo '; enabled, registering these variables consumes CPU cycles and memory each time' >> /tmp/php.ini
  echo '; a script is executed. For performance reasons, this feature should be disabled' >> /tmp/php.ini
  echo '; on production servers.' >> /tmp/php.ini
  echo '; Note: This directive is hardcoded to On for the CLI SAPI' >> /tmp/php.ini
  echo '; Default Value: On' >> /tmp/php.ini
  echo '; Development Value: Off' >> /tmp/php.ini
  echo '; Production Value: Off' >> /tmp/php.ini
  echo '; http://php.net/register-argc-argv' >> /tmp/php.ini
  echo 'register_argc_argv = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; When enabled, the ENV, REQUEST and SERVER variables are created when they"re' >> /tmp/php.ini
  echo '; first used (Just In Time) instead of when the script starts. If these' >> /tmp/php.ini
  echo '; variables are not used within a script, having this directive on will result' >> /tmp/php.ini
  echo '; in a performance gain. The PHP directive register_argc_argv must be disabled' >> /tmp/php.ini
  echo '; for this directive to have any affect.' >> /tmp/php.ini
  echo '; http://php.net/auto-globals-jit' >> /tmp/php.ini
  echo 'auto_globals_jit = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Whether PHP will read the POST data.' >> /tmp/php.ini
  echo '; This option is enabled by default.' >> /tmp/php.ini
  echo '; Most likely, you won"t want to disable this option globally. It causes $_POST' >> /tmp/php.ini
  echo '; and $_FILES to always be empty; the only way you will be able to read the' >> /tmp/php.ini
  echo '; POST data will be through the php://input stream wrapper. This can be useful' >> /tmp/php.ini
  echo '; to proxy requests or to process the POST data in a memory efficient fashion.' >> /tmp/php.ini
  echo '; http://php.net/enable-post-data-reading' >> /tmp/php.ini
  echo ';enable_post_data_reading = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum size of POST data that PHP will accept.' >> /tmp/php.ini
  echo '; Its value may be 0 to disable the limit. It is ignored if POST data reading' >> /tmp/php.ini
  echo '; is disabled through enable_post_data_reading.' >> /tmp/php.ini
  echo '; http://php.net/post-max-size' >> /tmp/php.ini
  echo 'post_max_size = 100M' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Automatically add files before PHP document.' >> /tmp/php.ini
  echo '; http://php.net/auto-prepend-file' >> /tmp/php.ini
  echo 'auto_prepend_file =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Automatically add files after PHP document.' >> /tmp/php.ini
  echo '; http://php.net/auto-append-file' >> /tmp/php.ini
  echo 'auto_append_file =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; By default, PHP will output a media type using the Content-Type header. To' >> /tmp/php.ini
  echo '; disable this, simply set it to be empty.' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; PHP"s built-in default media type is set to text/html.' >> /tmp/php.ini
  echo '; http://php.net/default-mimetype' >> /tmp/php.ini
  echo 'default_mimetype = "text/html"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; PHP"s default character set is set to UTF-8.' >> /tmp/php.ini
  echo '; http://php.net/default-charset' >> /tmp/php.ini
  echo 'default_charset = "UTF-8"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; PHP internal character encoding is set to empty.' >> /tmp/php.ini
  echo '; If empty, default_charset is used.' >> /tmp/php.ini
  echo '; http://php.net/internal-encoding' >> /tmp/php.ini
  echo ';internal_encoding =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; PHP input character encoding is set to empty.' >> /tmp/php.ini
  echo '; If empty, default_charset is used.' >> /tmp/php.ini
  echo '; http://php.net/input-encoding' >> /tmp/php.ini
  echo ';input_encoding =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; PHP output character encoding is set to empty.' >> /tmp/php.ini
  echo '; If empty, default_charset is used.' >> /tmp/php.ini
  echo '; See also output_buffer.' >> /tmp/php.ini
  echo '; http://php.net/output-encoding' >> /tmp/php.ini
  echo ';output_encoding =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Paths and Directories ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; UNIX: "/path1:/path2"' >> /tmp/php.ini
  echo ';include_path = ".:/usr/share/php"' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; Windows: "\path1;\path2"' >> /tmp/php.ini
  echo ';include_path = ".;c:\php\includes"' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; PHP"s default setting for include_path is ".;/path/to/php/pear"' >> /tmp/php.ini
  echo '; http://php.net/include-path' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The root of the PHP pages, used only if nonempty.' >> /tmp/php.ini
  echo '; if PHP was not compiled with FORCE_REDIRECT, you SHOULD set doc_root' >> /tmp/php.ini
  echo '; if you are running php as a CGI under any web server (other than IIS)' >> /tmp/php.ini
  echo '; see documentation for security issues.  The alternate is to use the' >> /tmp/php.ini
  echo '; cgi.force_redirect configuration below' >> /tmp/php.ini
  echo '; http://php.net/doc-root' >> /tmp/php.ini
  echo 'doc_root =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The directory under which PHP opens the script using /~username used only' >> /tmp/php.ini
  echo '; if nonempty.' >> /tmp/php.ini
  echo '; http://php.net/user-dir' >> /tmp/php.ini
  echo 'user_dir =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Directory in which the loadable extensions (modules) reside.' >> /tmp/php.ini
  echo '; http://php.net/extension-dir' >> /tmp/php.ini
  echo '; extension_dir = "./"' >> /tmp/php.ini
  echo '; On windows:' >> /tmp/php.ini
  echo '; extension_dir = "ext"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Directory where the temporary files should be placed.' >> /tmp/php.ini
  echo '; Defaults to the system default (see sys_get_temp_dir)' >> /tmp/php.ini
  echo '; sys_temp_dir = "/tmp"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Whether or not to enable the dl() function.  The dl() function does NOT work' >> /tmp/php.ini
  echo '; properly in multithreaded servers, such as IIS or Zeus, and is automatically' >> /tmp/php.ini
  echo '; disabled on them.' >> /tmp/php.ini
  echo '; http://php.net/enable-dl' >> /tmp/php.ini
  echo 'enable_dl = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; cgi.force_redirect is necessary to provide security running PHP as a CGI under' >> /tmp/php.ini
  echo '; most web servers.  Left undefined, PHP turns this on by default.  You can' >> /tmp/php.ini
  echo '; turn it off here AT YOUR OWN RISK' >> /tmp/php.ini
  echo '; **You CAN safely turn this off for IIS, in fact, you MUST.**' >> /tmp/php.ini
  echo '; http://php.net/cgi.force-redirect' >> /tmp/php.ini
  echo ';cgi.force_redirect = 1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; if cgi.nph is enabled it will force cgi to always sent Status: 200 with' >> /tmp/php.ini
  echo '; every request. PHP"s default behavior is to disable this feature.' >> /tmp/php.ini
  echo ';cgi.nph = 1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; if cgi.force_redirect is turned on, and you are not running under Apache or Netscape' >> /tmp/php.ini
  echo '; (iPlanet) web servers, you MAY need to set an environment variable name that PHP' >> /tmp/php.ini
  echo '; will look for to know it is OK to continue execution.  Setting this variable MAY' >> /tmp/php.ini
  echo '; cause security issues, KNOW WHAT YOU ARE DOING FIRST.' >> /tmp/php.ini
  echo '; http://php.net/cgi.redirect-status-env' >> /tmp/php.ini
  echo ';cgi.redirect_status_env =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; cgi.fix_pathinfo provides *real* PATH_INFO/PATH_TRANSLATED support for CGI.  PHP"s' >> /tmp/php.ini
  echo '; previous behaviour was to set PATH_TRANSLATED to SCRIPT_FILENAME, and to not grok' >> /tmp/php.ini
  echo '; what PATH_INFO is.  For more information on PATH_INFO, see the cgi specs.  Setting' >> /tmp/php.ini
  echo '; this to 1 will cause PHP CGI to fix its paths to conform to the spec.  A setting' >> /tmp/php.ini
  echo '; of zero causes PHP to behave as before.  Default is 1.  You should fix your scripts' >> /tmp/php.ini
  echo '; to use SCRIPT_FILENAME rather than PATH_TRANSLATED.' >> /tmp/php.ini
  echo '; http://php.net/cgi.fix-pathinfo' >> /tmp/php.ini
  echo 'cgi.fix_pathinfo=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; if cgi.discard_path is enabled, the PHP CGI binary can safely be placed outside' >> /tmp/php.ini
  echo '; of the web tree and people will not be able to circumvent .htaccess security.' >> /tmp/php.ini
  echo '; http://php.net/cgi.dicard-path' >> /tmp/php.ini
  echo ';cgi.discard_path=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; FastCGI under IIS (on WINNT based OS) supports the ability to impersonate' >> /tmp/php.ini
  echo '; security tokens of the calling client.  This allows IIS to define the' >> /tmp/php.ini
  echo '; security context that the request runs under.  mod_fastcgi under Apache' >> /tmp/php.ini
  echo '; does not currently support this feature (03/17/2002)' >> /tmp/php.ini
  echo '; Set to 1 if running under IIS.  Default is zero.' >> /tmp/php.ini
  echo '; http://php.net/fastcgi.impersonate' >> /tmp/php.ini
  echo ';fastcgi.impersonate = 1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Disable logging through FastCGI connection. PHP"s default behavior is to enable' >> /tmp/php.ini
  echo '; this feature.' >> /tmp/php.ini
  echo ';fastcgi.logging = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; cgi.rfc2616_headers configuration option tells PHP what type of headers to' >> /tmp/php.ini
  echo '; use when sending HTTP response code. If set to 0, PHP sends Status: header that' >> /tmp/php.ini
  echo '; is supported by Apache. When this option is set to 1, PHP will send' >> /tmp/php.ini
  echo '; RFC2616 compliant header.' >> /tmp/php.ini
  echo '; Default is zero.' >> /tmp/php.ini
  echo '; http://php.net/cgi.rfc2616-headers' >> /tmp/php.ini
  echo ';cgi.rfc2616_headers = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; cgi.check_shebang_line controls whether CGI PHP checks for line starting with #!' >> /tmp/php.ini
  echo '; (shebang) at the top of the running script. This line might be needed if the' >> /tmp/php.ini
  echo '; script support running both as stand-alone script and via PHP CGI<. PHP in CGI' >> /tmp/php.ini
  echo '; mode skips this line and ignores its content if this directive is turned on.' >> /tmp/php.ini
  echo '; http://php.net/cgi.check-shebang-line' >> /tmp/php.ini
  echo ';cgi.check_shebang_line=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; File Uploads ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Whether to allow HTTP file uploads.' >> /tmp/php.ini
  echo '; http://php.net/file-uploads' >> /tmp/php.ini
  echo 'file_uploads = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Temporary directory for HTTP uploaded files (will use system default if not' >> /tmp/php.ini
  echo '; specified).' >> /tmp/php.ini
  echo '; http://php.net/upload-tmp-dir' >> /tmp/php.ini
  echo 'upload_tmp_dir = /tmp' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum allowed size for uploaded files.' >> /tmp/php.ini
  echo '; http://php.net/upload-max-filesize' >> /tmp/php.ini
  echo 'upload_max_filesize = 20M' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of files that can be uploaded via a single request' >> /tmp/php.ini
  echo 'max_file_uploads = 20' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Fopen wrappers ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Whether to allow the treatment of URLs (like http:// or ftp://) as files.' >> /tmp/php.ini
  echo '; http://php.net/allow-url-fopen' >> /tmp/php.ini
  echo 'allow_url_fopen = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Whether to allow include/require to open URLs (like http:// or ftp://) as files.' >> /tmp/php.ini
  echo '; http://php.net/allow-url-include' >> /tmp/php.ini
  echo 'allow_url_include = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Define the anonymous ftp password (your email address). PHP"s default setting' >> /tmp/php.ini
  echo '; for this is empty.' >> /tmp/php.ini
  echo '; http://php.net/from' >> /tmp/php.ini
  echo ';from="john@doe.com"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Define the User-Agent string. PHP"s default setting for this is empty.' >> /tmp/php.ini
  echo '; http://php.net/user-agent' >> /tmp/php.ini
  echo ';user_agent="PHP"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default timeout for socket based streams (seconds)' >> /tmp/php.ini
  echo '; http://php.net/default-socket-timeout' >> /tmp/php.ini
  echo 'default_socket_timeout = 60' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If your scripts have to deal with files from Macintosh systems,' >> /tmp/php.ini
  echo '; or you are running on a Mac and need to deal with files from' >> /tmp/php.ini
  echo '; unix or win32 systems, setting this flag will cause PHP to' >> /tmp/php.ini
  echo '; automatically detect the EOL character in those files so that' >> /tmp/php.ini
  echo '; fgets() and file() will work regardless of the source of the file.' >> /tmp/php.ini
  echo '; http://php.net/auto-detect-line-endings' >> /tmp/php.ini
  echo ';auto_detect_line_endings = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Dynamic Extensions ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If you wish to have an extension loaded automatically, use the following' >> /tmp/php.ini
  echo '; syntax:' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo ';   extension=modulename.extension' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; For example, on Windows:' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo ';   extension=msql.dll' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; ... or under UNIX:' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo ';   extension=msql.so' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; ... or with a path:' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo ';   extension=/path/to/extension/msql.so' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; If you only provide the name of the extension, PHP will look for it in its' >> /tmp/php.ini
  echo '; default extension directory.' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; Windows Extensions' >> /tmp/php.ini
  echo '; Note that ODBC support is built in, so no dll is needed for it.' >> /tmp/php.ini
  echo '; Note that many DLL files are located in the extensions/ (PHP 4) ext/ (PHP 5+)' >> /tmp/php.ini
  echo '; extension folders as well as the separate PECL DLL download (PHP 5+).' >> /tmp/php.ini
  echo '; Be sure to appropriately set the extension_dir directive.' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo ';extension=php_bz2.dll' >> /tmp/php.ini
  echo ';extension=php_curl.dll' >> /tmp/php.ini
  echo ';extension=php_fileinfo.dll' >> /tmp/php.ini
  echo ';extension=php_ftp.dll' >> /tmp/php.ini
  echo ';extension=php_gd2.dll' >> /tmp/php.ini
  echo ';extension=php_gettext.dll' >> /tmp/php.ini
  echo ';extension=php_gmp.dll' >> /tmp/php.ini
  echo ';extension=php_intl.dll' >> /tmp/php.ini
  echo ';extension=php_imap.dll' >> /tmp/php.ini
  echo ';extension=php_interbase.dll' >> /tmp/php.ini
  echo ';extension=php_ldap.dll' >> /tmp/php.ini
  echo ';extension=php_mbstring.dll' >> /tmp/php.ini
  echo ';extension=php_exif.dll      ; Must be after mbstring as it depends on it' >> /tmp/php.ini
  echo ';extension=php_mysqli.dll' >> /tmp/php.ini
  echo ';extension=php_oci8_12c.dll  ; Use with Oracle Database 12c Instant Client' >> /tmp/php.ini
  echo ';extension=php_openssl.dll' >> /tmp/php.ini
  echo ';extension=php_pdo_firebird.dll' >> /tmp/php.ini
  echo ';extension=php_pdo_mysql.dll' >> /tmp/php.ini
  echo ';extension=php_pdo_oci.dll' >> /tmp/php.ini
  echo ';extension=php_pdo_odbc.dll' >> /tmp/php.ini
  echo ';extension=php_pdo_pgsql.dll' >> /tmp/php.ini
  echo ';extension=php_pdo_sqlite.dll' >> /tmp/php.ini
  echo ';extension=php_pgsql.dll' >> /tmp/php.ini
  echo ';extension=php_shmop.dll' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The MIBS data available in the PHP distribution must be installed.' >> /tmp/php.ini
  echo '; See http://www.php.net/manual/en/snmp.installation.php' >> /tmp/php.ini
  echo ';extension=php_snmp.dll' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';extension=php_soap.dll' >> /tmp/php.ini
  echo ';extension=php_sockets.dll' >> /tmp/php.ini
  echo ';extension=php_sqlite3.dll' >> /tmp/php.ini
  echo ';extension=php_tidy.dll' >> /tmp/php.ini
  echo ';extension=php_xmlrpc.dll' >> /tmp/php.ini
  echo ';extension=php_xsl.dll' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '; Module Settings ;' >> /tmp/php.ini
  echo ';;;;;;;;;;;;;;;;;;;' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[CLI Server]' >> /tmp/php.ini
  echo '; Whether the CLI web server uses ANSI color coding in its terminal output.' >> /tmp/php.ini
  echo 'cli_server.color = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Date]' >> /tmp/php.ini
  echo '; Defines the default timezone used by the date functions' >> /tmp/php.ini
  echo '; http://php.net/date.timezone' >> /tmp/php.ini
  echo 'date.timezone = Asia/Jakarta' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/date.default-latitude' >> /tmp/php.ini
  echo 'date.default_latitude = -6.211544' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/date.default-longitude' >> /tmp/php.ini
  echo 'date.default_longitude = 106.84517200000005' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/date.sunrise-zenith' >> /tmp/php.ini
  echo ';date.sunrise_zenith = 90.583333' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/date.sunset-zenith' >> /tmp/php.ini
  echo ';date.sunset_zenith = 90.583333' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[filter]' >> /tmp/php.ini
  echo '; http://php.net/filter.default' >> /tmp/php.ini
  echo ';filter.default = unsafe_raw' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/filter.default-flags' >> /tmp/php.ini
  echo ';filter.default_flags =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[iconv]' >> /tmp/php.ini
  echo '; Use of this INI entry is deprecated, use global input_encoding instead.' >> /tmp/php.ini
  echo '; If empty, default_charset or input_encoding or iconv.input_encoding is used.' >> /tmp/php.ini
  echo '; The precedence is: default_charset < intput_encoding < iconv.input_encoding' >> /tmp/php.ini
  echo ';iconv.input_encoding =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Use of this INI entry is deprecated, use global internal_encoding instead.' >> /tmp/php.ini
  echo '; If empty, default_charset or internal_encoding or iconv.internal_encoding is used.' >> /tmp/php.ini
  echo '; The precedence is: default_charset < internal_encoding < iconv.internal_encoding' >> /tmp/php.ini
  echo ';iconv.internal_encoding =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Use of this INI entry is deprecated, use global output_encoding instead.' >> /tmp/php.ini
  echo '; If empty, default_charset or output_encoding or iconv.output_encoding is used.' >> /tmp/php.ini
  echo '; The precedence is: default_charset < output_encoding < iconv.output_encoding' >> /tmp/php.ini
  echo '; To use an output encoding conversion, iconv"s output handler must be set' >> /tmp/php.ini
  echo '; otherwise output encoding conversion cannot be performed.' >> /tmp/php.ini
  echo ';iconv.output_encoding =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[intl]' >> /tmp/php.ini
  echo 'intl.default_locale = id_ID' >> /tmp/php.ini
  echo '; This directive allows you to produce PHP errors when some error' >> /tmp/php.ini
  echo '; happens within intl functions. The value is the level of the error produced.' >> /tmp/php.ini
  echo '; Default is 0, which does not produce any errors.' >> /tmp/php.ini
  echo ';intl.error_level = E_WARNING' >> /tmp/php.ini
  echo ';intl.use_exceptions = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[sqlite3]' >> /tmp/php.ini
  echo ';sqlite3.extension_dir =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Pcre]' >> /tmp/php.ini
  echo ';PCRE library backtracking limit.' >> /tmp/php.ini
  echo '; http://php.net/pcre.backtrack-limit' >> /tmp/php.ini
  echo ';pcre.backtrack_limit=100000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';PCRE library recursion limit.' >> /tmp/php.ini
  echo ';Please note that if you set this value to a high number you may consume all' >> /tmp/php.ini
  echo ';the available process stack and eventually crash PHP (due to reaching the' >> /tmp/php.ini
  echo ';stack size limit imposed by the Operating System).' >> /tmp/php.ini
  echo '; http://php.net/pcre.recursion-limit' >> /tmp/php.ini
  echo ';pcre.recursion_limit=100000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';Enables or disables JIT compilation of patterns. This requires the PCRE' >> /tmp/php.ini
  echo ';library to be compiled with JIT support.' >> /tmp/php.ini
  echo ';pcre.jit=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Pdo]' >> /tmp/php.ini
  echo '; Whether to pool ODBC connections. Can be one of "strict", "relaxed" or "off"' >> /tmp/php.ini
  echo '; http://php.net/pdo-odbc.connection-pooling' >> /tmp/php.ini
  echo ';pdo_odbc.connection_pooling=strict' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';pdo_odbc.db2_instance_name' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Pdo_mysql]' >> /tmp/php.ini
  echo '; If mysqlnd is used: Number of cache slots for the internal result set cache' >> /tmp/php.ini
  echo '; http://php.net/pdo_mysql.cache_size' >> /tmp/php.ini
  echo 'pdo_mysql.cache_size = 2000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default socket name for local MySQL connects.  If empty, uses the built-in' >> /tmp/php.ini
  echo '; MySQL defaults.' >> /tmp/php.ini
  echo '; http://php.net/pdo_mysql.default-socket' >> /tmp/php.ini
  echo 'pdo_mysql.default_socket=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Phar]' >> /tmp/php.ini
  echo '; http://php.net/phar.readonly' >> /tmp/php.ini
  echo ';phar.readonly = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/phar.require-hash' >> /tmp/php.ini
  echo ';phar.require_hash = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';phar.cache_list =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[mail function]' >> /tmp/php.ini
  echo '; For Win32 only.' >> /tmp/php.ini
  echo '; http://php.net/smtp' >> /tmp/php.ini
  echo 'SMTP = localhost' >> /tmp/php.ini
  echo '; http://php.net/smtp-port' >> /tmp/php.ini
  echo 'smtp_port = 25' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; For Win32 only.' >> /tmp/php.ini
  echo '; http://php.net/sendmail-from' >> /tmp/php.ini
  echo ';sendmail_from = me@example.com' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; For Unix only.  You may supply arguments as well (default: "sendmail -t -i").' >> /tmp/php.ini
  echo '; http://php.net/sendmail-path' >> /tmp/php.ini
  echo ';sendmail_path =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Force the addition of the specified parameters to be passed as extra parameters' >> /tmp/php.ini
  echo '; to the sendmail binary. These parameters will always replace the value of' >> /tmp/php.ini
  echo '; the 5th parameter to mail().' >> /tmp/php.ini
  echo ';mail.force_extra_parameters =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Add X-PHP-Originating-Script: that will include uid of the script followed by the filename' >> /tmp/php.ini
  echo 'mail.add_x_header = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The path to a log file that will log all mail() calls. Log entries include' >> /tmp/php.ini
  echo '; the full path of the script, line number, To address and headers.' >> /tmp/php.ini
  echo ';mail.log =' >> /tmp/php.ini
  echo '; Log mail to syslog (Event Log on Windows).' >> /tmp/php.ini
  echo ';mail.log = syslog' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[SQL]' >> /tmp/php.ini
  echo '; http://php.net/sql.safe-mode' >> /tmp/php.ini
  echo 'sql.safe_mode = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[ODBC]' >> /tmp/php.ini
  echo '; http://php.net/odbc.default-db' >> /tmp/php.ini
  echo ';odbc.default_db    =  Not yet implemented' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/odbc.default-user' >> /tmp/php.ini
  echo ';odbc.default_user  =  Not yet implemented' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/odbc.default-pw' >> /tmp/php.ini
  echo ';odbc.default_pw    =  Not yet implemented' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Controls the ODBC cursor model.' >> /tmp/php.ini
  echo '; Default: SQL_CURSOR_STATIC (default).' >> /tmp/php.ini
  echo ';odbc.default_cursortype' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Allow or prevent persistent links.' >> /tmp/php.ini
  echo '; http://php.net/odbc.allow-persistent' >> /tmp/php.ini
  echo 'odbc.allow_persistent = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Check that a connection is still valid before reuse.' >> /tmp/php.ini
  echo '; http://php.net/odbc.check-persistent' >> /tmp/php.ini
  echo 'odbc.check_persistent = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of persistent links.  -1 means no limit.' >> /tmp/php.ini
  echo '; http://php.net/odbc.max-persistent' >> /tmp/php.ini
  echo 'odbc.max_persistent = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of links (persistent + non-persistent).  -1 means no limit.' >> /tmp/php.ini
  echo '; http://php.net/odbc.max-links' >> /tmp/php.ini
  echo 'odbc.max_links = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Handling of LONG fields.  Returns number of bytes to variables.  0 means' >> /tmp/php.ini
  echo '; passthru.' >> /tmp/php.ini
  echo '; http://php.net/odbc.defaultlrl' >> /tmp/php.ini
  echo 'odbc.defaultlrl = 4096' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Handling of binary data.  0 means passthru, 1 return as is, 2 convert to char.' >> /tmp/php.ini
  echo '; See the documentation on odbc_binmode and odbc_longreadlen for an explanation' >> /tmp/php.ini
  echo '; of odbc.defaultlrl and odbc.defaultbinmode' >> /tmp/php.ini
  echo '; http://php.net/odbc.defaultbinmode' >> /tmp/php.ini
  echo 'odbc.defaultbinmode = 1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';birdstep.max_links = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Interbase]' >> /tmp/php.ini
  echo '; Allow or prevent persistent links.' >> /tmp/php.ini
  echo 'ibase.allow_persistent = 1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of persistent links.  -1 means no limit.' >> /tmp/php.ini
  echo 'ibase.max_persistent = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of links (persistent + non-persistent).  -1 means no limit.' >> /tmp/php.ini
  echo 'ibase.max_links = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default database name for ibase_connect().' >> /tmp/php.ini
  echo ';ibase.default_db =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default username for ibase_connect().' >> /tmp/php.ini
  echo ';ibase.default_user =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default password for ibase_connect().' >> /tmp/php.ini
  echo ';ibase.default_password =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default charset for ibase_connect().' >> /tmp/php.ini
  echo ';ibase.default_charset =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default timestamp format.' >> /tmp/php.ini
  echo 'ibase.timestampformat = "%Y-%m-%d %H:%M:%S"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default date format.' >> /tmp/php.ini
  echo 'ibase.dateformat = "%Y-%m-%d"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default time format.' >> /tmp/php.ini
  echo 'ibase.timeformat = "%H:%M:%S"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[MySQLi]' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of persistent links.  -1 means no limit.' >> /tmp/php.ini
  echo '; http://php.net/mysqli.max-persistent' >> /tmp/php.ini
  echo 'mysqli.max_persistent = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Allow accessing, from PHP"s perspective, local files with LOAD DATA statements' >> /tmp/php.ini
  echo '; http://php.net/mysqli.allow_local_infile' >> /tmp/php.ini
  echo ';mysqli.allow_local_infile = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Allow or prevent persistent links.' >> /tmp/php.ini
  echo '; http://php.net/mysqli.allow-persistent' >> /tmp/php.ini
  echo 'mysqli.allow_persistent = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of links.  -1 means no limit.' >> /tmp/php.ini
  echo '; http://php.net/mysqli.max-links' >> /tmp/php.ini
  echo 'mysqli.max_links = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If mysqlnd is used: Number of cache slots for the internal result set cache' >> /tmp/php.ini
  echo '; http://php.net/mysqli.cache_size' >> /tmp/php.ini
  echo 'mysqli.cache_size = 2000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default port number for mysqli_connect().  If unset, mysqli_connect() will use' >> /tmp/php.ini
  echo '; the $MYSQL_TCP_PORT or the mysql-tcp entry in /etc/services or the' >> /tmp/php.ini
  echo '; compile-time value defined MYSQL_PORT (in that order).  Win32 will only look' >> /tmp/php.ini
  echo '; at MYSQL_PORT.' >> /tmp/php.ini
  echo '; http://php.net/mysqli.default-port' >> /tmp/php.ini
  echo 'mysqli.default_port = 3306' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default socket name for local MySQL connects.  If empty, uses the built-in' >> /tmp/php.ini
  echo '; MySQL defaults.' >> /tmp/php.ini
  echo '; http://php.net/mysqli.default-socket' >> /tmp/php.ini
  echo 'mysqli.default_socket =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default host for mysql_connect() (doesn"t apply in safe mode).' >> /tmp/php.ini
  echo '; http://php.net/mysqli.default-host' >> /tmp/php.ini
  echo 'mysqli.default_host =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default user for mysql_connect() (doesn"t apply in safe mode).' >> /tmp/php.ini
  echo '; http://php.net/mysqli.default-user' >> /tmp/php.ini
  echo 'mysqli.default_user =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default password for mysqli_connect() (doesn"t apply in safe mode).' >> /tmp/php.ini
  echo '; Note that this is generally a *bad* idea to store passwords in this file.' >> /tmp/php.ini
  echo '; *Any* user with PHP access can run "echo get_cfg_var("mysqli.default_pw")' >> /tmp/php.ini
  echo '; and reveal this password!  And of course, any users with read access to this' >> /tmp/php.ini
  echo '; file will be able to reveal the password as well.' >> /tmp/php.ini
  echo '; http://php.net/mysqli.default-pw' >> /tmp/php.ini
  echo 'mysqli.default_pw =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Allow or prevent reconnect' >> /tmp/php.ini
  echo 'mysqli.reconnect = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[mysqlnd]' >> /tmp/php.ini
  echo '; Enable / Disable collection of general statistics by mysqlnd which can be' >> /tmp/php.ini
  echo '; used to tune and monitor MySQL operations.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.collect_statistics' >> /tmp/php.ini
  echo 'mysqlnd.collect_statistics = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enable / Disable collection of memory usage statistics by mysqlnd which can be' >> /tmp/php.ini
  echo '; used to tune and monitor MySQL operations.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.collect_memory_statistics' >> /tmp/php.ini
  echo 'mysqlnd.collect_memory_statistics = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Records communication from all extensions using mysqlnd to the specified log' >> /tmp/php.ini
  echo '; file.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.debug' >> /tmp/php.ini
  echo ';mysqlnd.debug =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Defines which queries will be logged.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.log_mask' >> /tmp/php.ini
  echo ';mysqlnd.log_mask = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Default size of the mysqlnd memory pool, which is used by result sets.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.mempool_default_size' >> /tmp/php.ini
  echo ';mysqlnd.mempool_default_size = 16000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Size of a pre-allocated buffer used when sending commands to MySQL in bytes.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.net_cmd_buffer_size' >> /tmp/php.ini
  echo ';mysqlnd.net_cmd_buffer_size = 2048' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Size of a pre-allocated buffer used for reading data sent by the server in' >> /tmp/php.ini
  echo '; bytes.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.net_read_buffer_size' >> /tmp/php.ini
  echo ';mysqlnd.net_read_buffer_size = 32768' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Timeout for network requests in seconds.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.net_read_timeout' >> /tmp/php.ini
  echo ';mysqlnd.net_read_timeout = 31536000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; SHA-256 Authentication Plugin related. File with the MySQL server public RSA' >> /tmp/php.ini
  echo '; key.' >> /tmp/php.ini
  echo '; http://php.net/mysqlnd.sha256_server_public_key' >> /tmp/php.ini
  echo ';mysqlnd.sha256_server_public_key =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[OCI8]' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Connection: Enables privileged connections using external' >> /tmp/php.ini
  echo '; credentials (OCI_SYSOPER, OCI_SYSDBA)' >> /tmp/php.ini
  echo '; http://php.net/oci8.privileged-connect' >> /tmp/php.ini
  echo ';oci8.privileged_connect = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Connection: The maximum number of persistent OCI8 connections per' >> /tmp/php.ini
  echo '; process. Using -1 means no limit.' >> /tmp/php.ini
  echo '; http://php.net/oci8.max-persistent' >> /tmp/php.ini
  echo ';oci8.max_persistent = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Connection: The maximum number of seconds a process is allowed to' >> /tmp/php.ini
  echo '; maintain an idle persistent connection. Using -1 means idle' >> /tmp/php.ini
  echo '; persistent connections will be maintained forever.' >> /tmp/php.ini
  echo '; http://php.net/oci8.persistent-timeout' >> /tmp/php.ini
  echo ';oci8.persistent_timeout = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Connection: The number of seconds that must pass before issuing a' >> /tmp/php.ini
  echo '; ping during oci_pconnect() to check the connection validity. When' >> /tmp/php.ini
  echo '; set to 0, each oci_pconnect() will cause a ping. Using -1 disables' >> /tmp/php.ini
  echo '; pings completely.' >> /tmp/php.ini
  echo '; http://php.net/oci8.ping-interval' >> /tmp/php.ini
  echo ';oci8.ping_interval = 60' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Connection: Set this to a user chosen connection class to be used' >> /tmp/php.ini
  echo '; for all pooled server requests with Oracle 11g Database Resident' >> /tmp/php.ini
  echo '; Connection Pooling (DRCP).  To use DRCP, this value should be set to' >> /tmp/php.ini
  echo '; the same string for all web servers running the same application,' >> /tmp/php.ini
  echo '; the database pool must be configured, and the connection string must' >> /tmp/php.ini
  echo '; specify to use a pooled server.' >> /tmp/php.ini
  echo ';oci8.connection_class =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; High Availability: Using On lets PHP receive Fast Application' >> /tmp/php.ini
  echo '; Notification (FAN) events generated when a database node fails. The' >> /tmp/php.ini
  echo '; database must also be configured to post FAN events.' >> /tmp/php.ini
  echo ';oci8.events = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Tuning: This option enables statement caching, and specifies how' >> /tmp/php.ini
  echo '; many statements to cache. Using 0 disables statement caching.' >> /tmp/php.ini
  echo '; http://php.net/oci8.statement-cache-size' >> /tmp/php.ini
  echo ';oci8.statement_cache_size = 20' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Tuning: Enables statement prefetching and sets the default number of' >> /tmp/php.ini
  echo '; rows that will be fetched automatically after statement execution.' >> /tmp/php.ini
  echo '; http://php.net/oci8.default-prefetch' >> /tmp/php.ini
  echo ';oci8.default_prefetch = 100' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Compatibility. Using On means oci_close() will not close' >> /tmp/php.ini
  echo '; oci_connect() and oci_new_connect() connections.' >> /tmp/php.ini
  echo '; http://php.net/oci8.old-oci-close-semantics' >> /tmp/php.ini
  echo ';oci8.old_oci_close_semantics = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[PostgreSQL]' >> /tmp/php.ini
  echo '; Allow or prevent persistent links.' >> /tmp/php.ini
  echo '; http://php.net/pgsql.allow-persistent' >> /tmp/php.ini
  echo 'pgsql.allow_persistent = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Detect broken persistent links always with pg_pconnect().' >> /tmp/php.ini
  echo '; Auto reset feature requires a little overheads.' >> /tmp/php.ini
  echo '; http://php.net/pgsql.auto-reset-persistent' >> /tmp/php.ini
  echo 'pgsql.auto_reset_persistent = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of persistent links.  -1 means no limit.' >> /tmp/php.ini
  echo '; http://php.net/pgsql.max-persistent' >> /tmp/php.ini
  echo 'pgsql.max_persistent = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Maximum number of links (persistent+non persistent).  -1 means no limit.' >> /tmp/php.ini
  echo '; http://php.net/pgsql.max-links' >> /tmp/php.ini
  echo 'pgsql.max_links = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Ignore PostgreSQL backends Notice message or not.' >> /tmp/php.ini
  echo '; Notice message logging require a little overheads.' >> /tmp/php.ini
  echo '; http://php.net/pgsql.ignore-notice' >> /tmp/php.ini
  echo 'pgsql.ignore_notice = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Log PostgreSQL backends Notice message or not.' >> /tmp/php.ini
  echo '; Unless pgsql.ignore_notice=0, module cannot log notice message.' >> /tmp/php.ini
  echo '; http://php.net/pgsql.log-notice' >> /tmp/php.ini
  echo 'pgsql.log_notice = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[bcmath]' >> /tmp/php.ini
  echo '; Number of decimal digits for all bcmath functions.' >> /tmp/php.ini
  echo '; http://php.net/bcmath.scale' >> /tmp/php.ini
  echo 'bcmath.scale = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[browscap]' >> /tmp/php.ini
  echo '; http://php.net/browscap' >> /tmp/php.ini
  echo ';browscap = extra/browscap.ini' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Session]' >> /tmp/php.ini
  echo '; Handler used to store/retrieve data.' >> /tmp/php.ini
  echo '; http://php.net/session.save-handler' >> /tmp/php.ini
  echo 'session.save_handler = files' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Argument passed to save_handler.  In the case of files, this is the path' >> /tmp/php.ini
  echo '; where data files are stored. Note: Windows users have to change this' >> /tmp/php.ini
  echo '; variable in order to use PHP"s session functions.' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; The path can be defined as:' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo ';     session.save_path = "N;/path"' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; where N is an integer.  Instead of storing all the session files in' >> /tmp/php.ini
  echo '; /path, what this will do is use subdirectories N-levels deep, and' >> /tmp/php.ini
  echo '; store the session data in those directories.  This is useful if' >> /tmp/php.ini
  echo '; your OS has problems with many files in one directory, and is' >> /tmp/php.ini
  echo '; a more efficient layout for servers that handle many sessions.' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; NOTE 1: PHP will not create this directory structure automatically.' >> /tmp/php.ini
  echo ';         You can use the script in the ext/session dir for that purpose.' >> /tmp/php.ini
  echo '; NOTE 2: See the section on garbage collection below if you choose to' >> /tmp/php.ini
  echo ';         use subdirectories for session storage' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; The file storage module creates files using mode 600 by default.' >> /tmp/php.ini
  echo '; You can change that by using' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo ';     session.save_path = "N;MODE;/path"' >> /tmp/php.ini
  echo ';' >> /tmp/php.ini
  echo '; where MODE is the octal representation of the mode. Note that this' >> /tmp/php.ini
  echo '; does not overwrite the process"s umask.' >> /tmp/php.ini
  echo '; http://php.net/session.save-path' >> /tmp/php.ini
  echo 'session.save_path = "/var/lib/php/7.1/sessions"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Whether to use strict session mode.' >> /tmp/php.ini
  echo '; Strict session mode does not accept uninitialized session ID and regenerate' >> /tmp/php.ini
  echo '; session ID if browser sends uninitialized session ID. Strict mode protects' >> /tmp/php.ini
  echo '; applications from session fixation via session adoption vulnerability. It is' >> /tmp/php.ini
  echo '; disabled by default for maximum compatibility, but enabling it is encouraged.' >> /tmp/php.ini
  echo '; https://wiki.php.net/rfc/strict_sessions' >> /tmp/php.ini
  echo 'session.use_strict_mode = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Whether to use cookies.' >> /tmp/php.ini
  echo '; http://php.net/session.use-cookies' >> /tmp/php.ini
  echo 'session.use_cookies = 1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/session.cookie-secure' >> /tmp/php.ini
  echo ';session.cookie_secure =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This option forces PHP to fetch and use a cookie for storing and maintaining' >> /tmp/php.ini
  echo '; the session id. We encourage this operation as it"s very helpful in combating' >> /tmp/php.ini
  echo '; session hijacking when not specifying and managing your own session id. It is' >> /tmp/php.ini
  echo '; not the be-all and end-all of session hijacking defense, but it"s a good start.' >> /tmp/php.ini
  echo '; http://php.net/session.use-only-cookies' >> /tmp/php.ini
  echo 'session.use_only_cookies = 1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Name of the session (used as cookie name).' >> /tmp/php.ini
  echo '; http://php.net/session.name' >> /tmp/php.ini
  echo 'session.name = PHPSESSID' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Initialize session on request startup.' >> /tmp/php.ini
  echo '; http://php.net/session.auto-start' >> /tmp/php.ini
  echo 'session.auto_start = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Lifetime in seconds of cookie or, if 0, until browser is restarted.' >> /tmp/php.ini
  echo '; http://php.net/session.cookie-lifetime' >> /tmp/php.ini
  echo 'session.cookie_lifetime = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The path for which the cookie is valid.' >> /tmp/php.ini
  echo '; http://php.net/session.cookie-path' >> /tmp/php.ini
  echo 'session.cookie_path = /' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The domain for which the cookie is valid.' >> /tmp/php.ini
  echo '; http://php.net/session.cookie-domain' >> /tmp/php.ini
  echo 'session.cookie_domain =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Whether or not to add the httpOnly flag to the cookie, which makes it inaccessible to browser scripting languages such as JavaScript.' >> /tmp/php.ini
  echo '; http://php.net/session.cookie-httponly' >> /tmp/php.ini
  echo 'session.cookie_httponly =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Handler used to serialize data.  php is the standard serializer of PHP.' >> /tmp/php.ini
  echo '; http://php.net/session.serialize-handler' >> /tmp/php.ini
  echo 'session.serialize_handler = php' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Defines the probability that the "garbage collection" process is started' >> /tmp/php.ini
  echo '; on every session initialization. The probability is calculated by using' >> /tmp/php.ini
  echo '; gc_probability/gc_divisor. Where session.gc_probability is the numerator' >> /tmp/php.ini
  echo '; and gc_divisor is the denominator in the equation. Setting this value to 1' >> /tmp/php.ini
  echo '; when the session.gc_divisor value is 100 will give you approximately a 1% chance' >> /tmp/php.ini
  echo '; the gc will run on any give request.' >> /tmp/php.ini
  echo '; Default Value: 1' >> /tmp/php.ini
  echo '; Development Value: 1' >> /tmp/php.ini
  echo '; Production Value: 1' >> /tmp/php.ini
  echo '; http://php.net/session.gc-probability' >> /tmp/php.ini
  echo 'session.gc_probability = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Defines the probability that the "garbage collection" process is started on every' >> /tmp/php.ini
  echo '; session initialization. The probability is calculated by using the following equation:' >> /tmp/php.ini
  echo '; gc_probability/gc_divisor. Where session.gc_probability is the numerator and' >> /tmp/php.ini
  echo '; session.gc_divisor is the denominator in the equation. Setting this value to 1' >> /tmp/php.ini
  echo '; when the session.gc_divisor value is 100 will give you approximately a 1% chance' >> /tmp/php.ini
  echo '; the gc will run on any give request. Increasing this value to 1000 will give you' >> /tmp/php.ini
  echo '; a 0.1% chance the gc will run on any give request. For high volume production servers,' >> /tmp/php.ini
  echo '; this is a more efficient approach.' >> /tmp/php.ini
  echo '; Default Value: 100' >> /tmp/php.ini
  echo '; Development Value: 1000' >> /tmp/php.ini
  echo '; Production Value: 1000' >> /tmp/php.ini
  echo '; http://php.net/session.gc-divisor' >> /tmp/php.ini
  echo 'session.gc_divisor = 1000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; After this number of seconds, stored data will be seen as "garbage" and' >> /tmp/php.ini
  echo '; cleaned up by the garbage collection process.' >> /tmp/php.ini
  echo '; http://php.net/session.gc-maxlifetime' >> /tmp/php.ini
  echo 'session.gc_maxlifetime = 1440' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; NOTE: If you are using the subdirectory option for storing session files' >> /tmp/php.ini
  echo ';       (see session.save_path above), then garbage collection does *not*' >> /tmp/php.ini
  echo ';       happen automatically.  You will need to do your own garbage' >> /tmp/php.ini
  echo ';       collection through a shell script, cron entry, or some other method.' >> /tmp/php.ini
  echo ';       For example, the following script would is the equivalent of' >> /tmp/php.ini
  echo ';       setting session.gc_maxlifetime to 1440 (1440 seconds = 24 minutes):' >> /tmp/php.ini
  echo ';          find /path/to/sessions -cmin +24 -type f | xargs rm' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Check HTTP Referer to invalidate externally stored URLs containing ids.' >> /tmp/php.ini
  echo '; HTTP_REFERER has to contain this substring for the session to be' >> /tmp/php.ini
  echo '; considered as valid.' >> /tmp/php.ini
  echo '; http://php.net/session.referer-check' >> /tmp/php.ini
  echo 'session.referer_check =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Set to {nocache,private,public,} to determine HTTP caching aspects' >> /tmp/php.ini
  echo '; or leave this empty to avoid sending anti-caching headers.' >> /tmp/php.ini
  echo '; http://php.net/session.cache-limiter' >> /tmp/php.ini
  echo 'session.cache_limiter = nocache' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Document expires after n minutes.' >> /tmp/php.ini
  echo '; http://php.net/session.cache-expire' >> /tmp/php.ini
  echo 'session.cache_expire = 180' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; trans sid support is disabled by default.' >> /tmp/php.ini
  echo '; Use of trans sid may risk your users" security.' >> /tmp/php.ini
  echo '; Use this option with caution.' >> /tmp/php.ini
  echo '; - User may send URL contains active session ID' >> /tmp/php.ini
  echo ';   to other person via. email/irc/etc.' >> /tmp/php.ini
  echo '; - URL that contains active session ID may be stored' >> /tmp/php.ini
  echo ';   in publicly accessible computer.' >> /tmp/php.ini
  echo '; - User may access your site with the same session ID' >> /tmp/php.ini
  echo ';   always using URL stored in browser"s history or bookmarks.' >> /tmp/php.ini
  echo '; http://php.net/session.use-trans-sid' >> /tmp/php.ini
  echo 'session.use_trans_sid = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Set session ID character length. This value could be between 22 to 256.' >> /tmp/php.ini
  echo '; Shorter length than default is supported only for compatibility reason.' >> /tmp/php.ini
  echo '; Users should use 32 or more chars.' >> /tmp/php.ini
  echo '; http://php.net/session.sid-length' >> /tmp/php.ini
  echo '; Default Value: 32' >> /tmp/php.ini
  echo '; Development Value: 26' >> /tmp/php.ini
  echo '; Production Value: 26' >> /tmp/php.ini
  echo 'session.sid_length = 26' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The URL rewriter will look for URLs in a defined set of HTML tags.' >> /tmp/php.ini
  echo '; <form> is special; if you include them here, the rewriter will' >> /tmp/php.ini
  echo '; add a hidden <input> field with the info which is otherwise appended' >> /tmp/php.ini
  echo '; to URLs. <form> tag"s action attribute URL will not be modified' >> /tmp/php.ini
  echo '; unless it is specified.' >> /tmp/php.ini
  echo '; Note that all valid entries require a "=", even if no value follows.' >> /tmp/php.ini
  echo '; Default Value: "a=href,area=href,frame=src,form="' >> /tmp/php.ini
  echo '; Development Value: "a=href,area=href,frame=src,form="' >> /tmp/php.ini
  echo '; Production Value: "a=href,area=href,frame=src,form="' >> /tmp/php.ini
  echo '; http://php.net/url-rewriter.tags' >> /tmp/php.ini
  echo 'session.trans_sid_tags = "a=href,area=href,frame=src,form="' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; URL rewriter does not rewrite absolute URLs by default.' >> /tmp/php.ini
  echo '; To enable rewrites for absolute pathes, target hosts must be specified' >> /tmp/php.ini
  echo '; at RUNTIME. i.e. use ini_set()' >> /tmp/php.ini
  echo '; <form> tags is special. PHP will check action attribute"s URL regardless' >> /tmp/php.ini
  echo '; of session.trans_sid_tags setting.' >> /tmp/php.ini
  echo '; If no host is defined, HTTP_HOST will be used for allowed host.' >> /tmp/php.ini
  echo '; Example value: php.net,www.php.net,wiki.php.net' >> /tmp/php.ini
  echo '; Use "," for multiple hosts. No spaces are allowed.' >> /tmp/php.ini
  echo '; Default Value: ""' >> /tmp/php.ini
  echo '; Development Value: ""' >> /tmp/php.ini
  echo '; Production Value: ""' >> /tmp/php.ini
  echo ';session.trans_sid_hosts=""' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Define how many bits are stored in each character when converting' >> /tmp/php.ini
  echo '; the binary hash data to something readable.' >> /tmp/php.ini
  echo '; Possible values:' >> /tmp/php.ini
  echo ';   4  (4 bits: 0-9, a-f)' >> /tmp/php.ini
  echo ';   5  (5 bits: 0-9, a-v)' >> /tmp/php.ini
  echo ';   6  (6 bits: 0-9, a-z, A-Z, "-", ",")' >> /tmp/php.ini
  echo '; Default Value: 4' >> /tmp/php.ini
  echo '; Development Value: 5' >> /tmp/php.ini
  echo '; Production Value: 5' >> /tmp/php.ini
  echo '; http://php.net/session.hash-bits-per-character' >> /tmp/php.ini
  echo 'session.sid_bits_per_character = 5' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enable upload progress tracking in $_SESSION' >> /tmp/php.ini
  echo '; Default Value: On' >> /tmp/php.ini
  echo '; Development Value: On' >> /tmp/php.ini
  echo '; Production Value: On' >> /tmp/php.ini
  echo '; http://php.net/session.upload-progress.enabled' >> /tmp/php.ini
  echo ';session.upload_progress.enabled = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Cleanup the progress information as soon as all POST data has been read' >> /tmp/php.ini
  echo '; (i.e. upload completed).' >> /tmp/php.ini
  echo '; Default Value: On' >> /tmp/php.ini
  echo '; Development Value: On' >> /tmp/php.ini
  echo '; Production Value: On' >> /tmp/php.ini
  echo '; http://php.net/session.upload-progress.cleanup' >> /tmp/php.ini
  echo ';session.upload_progress.cleanup = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; A prefix used for the upload progress key in $_SESSION' >> /tmp/php.ini
  echo '; Default Value: "upload_progress_"' >> /tmp/php.ini
  echo '; Development Value: "upload_progress_"' >> /tmp/php.ini
  echo '; Production Value: "upload_progress_"' >> /tmp/php.ini
  echo '; http://php.net/session.upload-progress.prefix' >> /tmp/php.ini
  echo ';session.upload_progress.prefix = "upload_progress_"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The index name (concatenated with the prefix) in $_SESSION' >> /tmp/php.ini
  echo '; containing the upload progress information' >> /tmp/php.ini
  echo '; Default Value: "PHP_SESSION_UPLOAD_PROGRESS"' >> /tmp/php.ini
  echo '; Development Value: "PHP_SESSION_UPLOAD_PROGRESS"' >> /tmp/php.ini
  echo '; Production Value: "PHP_SESSION_UPLOAD_PROGRESS"' >> /tmp/php.ini
  echo '; http://php.net/session.upload-progress.name' >> /tmp/php.ini
  echo ';session.upload_progress.name = "PHP_SESSION_UPLOAD_PROGRESS"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; How frequently the upload progress should be updated.' >> /tmp/php.ini
  echo '; Given either in percentages (per-file), or in bytes' >> /tmp/php.ini
  echo '; Default Value: "1%"' >> /tmp/php.ini
  echo '; Development Value: "1%"' >> /tmp/php.ini
  echo '; Production Value: "1%"' >> /tmp/php.ini
  echo '; http://php.net/session.upload-progress.freq' >> /tmp/php.ini
  echo ';session.upload_progress.freq =  "1%"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The minimum delay between updates, in seconds' >> /tmp/php.ini
  echo '; Default Value: 1' >> /tmp/php.ini
  echo '; Development Value: 1' >> /tmp/php.ini
  echo '; Production Value: 1' >> /tmp/php.ini
  echo '; http://php.net/session.upload-progress.min-freq' >> /tmp/php.ini
  echo ';session.upload_progress.min_freq = "1"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Only write session data when session data is changed. Enabled by default.' >> /tmp/php.ini
  echo '; http://php.net/session.lazy-write' >> /tmp/php.ini
  echo ';session.lazy_write = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Assertion]' >> /tmp/php.ini
  echo '; Switch whether to compile assertions at all (to have no overhead at run-time)' >> /tmp/php.ini
  echo '; -1: Do not compile at all' >> /tmp/php.ini
  echo ';  0: Jump over assertion at run-time' >> /tmp/php.ini
  echo ';  1: Execute assertions' >> /tmp/php.ini
  echo '; Changing from or to a negative value is only possible in php.ini! (For turning assertions on and off at run-time, see assert.active, when zend.assertions = 1)' >> /tmp/php.ini
  echo '; Default Value: 1' >> /tmp/php.ini
  echo '; Development Value: 1' >> /tmp/php.ini
  echo '; Production Value: -1' >> /tmp/php.ini
  echo '; http://php.net/zend.assertions' >> /tmp/php.ini
  echo 'zend.assertions = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Assert(expr); active by default.' >> /tmp/php.ini
  echo '; http://php.net/assert.active' >> /tmp/php.ini
  echo ';assert.active = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Throw an AssertationException on failed assertions' >> /tmp/php.ini
  echo '; http://php.net/assert.exception' >> /tmp/php.ini
  echo ';assert.exception = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Issue a PHP warning for each failed assertion. (Overridden by assert.exception if active)' >> /tmp/php.ini
  echo '; http://php.net/assert.warning' >> /tmp/php.ini
  echo ';assert.warning = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Don"t bail out by default.' >> /tmp/php.ini
  echo '; http://php.net/assert.bail' >> /tmp/php.ini
  echo ';assert.bail = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; User-function to be called if an assertion fails.' >> /tmp/php.ini
  echo '; http://php.net/assert.callback' >> /tmp/php.ini
  echo ';assert.callback = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Eval the expression with current error_reporting().  Set to true if you want' >> /tmp/php.ini
  echo '; error_reporting(0) around the eval().' >> /tmp/php.ini
  echo '; http://php.net/assert.quiet-eval' >> /tmp/php.ini
  echo ';assert.quiet_eval = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[COM]' >> /tmp/php.ini
  echo '; path to a file containing GUIDs, IIDs or filenames of files with TypeLibs' >> /tmp/php.ini
  echo '; http://php.net/com.typelib-file' >> /tmp/php.ini
  echo ';com.typelib_file =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; allow Distributed-COM calls' >> /tmp/php.ini
  echo '; http://php.net/com.allow-dcom' >> /tmp/php.ini
  echo ';com.allow_dcom = true' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; autoregister constants of a components typlib on com_load()' >> /tmp/php.ini
  echo '; http://php.net/com.autoregister-typelib' >> /tmp/php.ini
  echo ';com.autoregister_typelib = true' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; register constants casesensitive' >> /tmp/php.ini
  echo '; http://php.net/com.autoregister-casesensitive' >> /tmp/php.ini
  echo ';com.autoregister_casesensitive = false' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; show warnings on duplicate constant registrations' >> /tmp/php.ini
  echo '; http://php.net/com.autoregister-verbose' >> /tmp/php.ini
  echo ';com.autoregister_verbose = true' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The default character set code-page to use when passing strings to and from COM objects.' >> /tmp/php.ini
  echo '; Default: system ANSI code page' >> /tmp/php.ini
  echo ';com.code_page=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[mbstring]' >> /tmp/php.ini
  echo '; language for internal character representation.' >> /tmp/php.ini
  echo '; This affects mb_send_mail() and mbstring.detect_order.' >> /tmp/php.ini
  echo '; http://php.net/mbstring.language' >> /tmp/php.ini
  echo ';mbstring.language = Japanese' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Use of this INI entry is deprecated, use global internal_encoding instead.' >> /tmp/php.ini
  echo '; internal/script encoding.' >> /tmp/php.ini
  echo '; Some encoding cannot work as internal encoding. (e.g. SJIS, BIG5, ISO-2022-*)' >> /tmp/php.ini
  echo '; If empty, default_charset or internal_encoding or iconv.internal_encoding is used.' >> /tmp/php.ini
  echo '; The precedence is: default_charset < internal_encoding < iconv.internal_encoding' >> /tmp/php.ini
  echo ';mbstring.internal_encoding =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Use of this INI entry is deprecated, use global input_encoding instead.' >> /tmp/php.ini
  echo '; http input encoding.' >> /tmp/php.ini
  echo '; mbstring.encoding_traslation = On is needed to use this setting.' >> /tmp/php.ini
  echo '; If empty, default_charset or input_encoding or mbstring.input is used.' >> /tmp/php.ini
  echo '; The precedence is: default_charset < intput_encoding < mbsting.http_input' >> /tmp/php.ini
  echo '; http://php.net/mbstring.http-input' >> /tmp/php.ini
  echo ';mbstring.http_input =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Use of this INI entry is deprecated, use global output_encoding instead.' >> /tmp/php.ini
  echo '; http output encoding.' >> /tmp/php.ini
  echo '; mb_output_handler must be registered as output buffer to function.' >> /tmp/php.ini
  echo '; If empty, default_charset or output_encoding or mbstring.http_output is used.' >> /tmp/php.ini
  echo '; The precedence is: default_charset < output_encoding < mbstring.http_output' >> /tmp/php.ini
  echo '; To use an output encoding conversion, mbstring"s output handler must be set' >> /tmp/php.ini
  echo '; otherwise output encoding conversion cannot be performed.' >> /tmp/php.ini
  echo '; http://php.net/mbstring.http-output' >> /tmp/php.ini
  echo ';mbstring.http_output =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; enable automatic encoding translation according to' >> /tmp/php.ini
  echo '; mbstring.internal_encoding setting. Input chars are' >> /tmp/php.ini
  echo '; converted to internal encoding by setting this to On.' >> /tmp/php.ini
  echo '; Note: Do _not_ use automatic encoding translation for' >> /tmp/php.ini
  echo ';       portable libs/applications.' >> /tmp/php.ini
  echo '; http://php.net/mbstring.encoding-translation' >> /tmp/php.ini
  echo ';mbstring.encoding_translation = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; automatic encoding detection order.' >> /tmp/php.ini
  echo '; "auto" detect order is changed according to mbstring.language' >> /tmp/php.ini
  echo '; http://php.net/mbstring.detect-order' >> /tmp/php.ini
  echo ';mbstring.detect_order = auto' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; substitute_character used when character cannot be converted' >> /tmp/php.ini
  echo '; one from another' >> /tmp/php.ini
  echo '; http://php.net/mbstring.substitute-character' >> /tmp/php.ini
  echo ';mbstring.substitute_character = none' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; overload(replace) single byte functions by mbstring functions.' >> /tmp/php.ini
  echo '; mail(), ereg(), etc are overloaded by mb_send_mail(), mb_ereg(),' >> /tmp/php.ini
  echo '; etc. Possible values are 0,1,2,4 or combination of them.' >> /tmp/php.ini
  echo '; For example, 7 for overload everything.' >> /tmp/php.ini
  echo '; 0: No overload' >> /tmp/php.ini
  echo '; 1: Overload mail() function' >> /tmp/php.ini
  echo '; 2: Overload str*() functions' >> /tmp/php.ini
  echo '; 4: Overload ereg*() functions' >> /tmp/php.ini
  echo '; http://php.net/mbstring.func-overload' >> /tmp/php.ini
  echo ';mbstring.func_overload = 0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; enable strict encoding detection.' >> /tmp/php.ini
  echo '; Default: Off' >> /tmp/php.ini
  echo ';mbstring.strict_detection = On' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; This directive specifies the regex pattern of content types for which mb_output_handler()' >> /tmp/php.ini
  echo '; is activated.' >> /tmp/php.ini
  echo '; Default: mbstring.http_output_conv_mimetype=^(text/|application/xhtml\+xml)' >> /tmp/php.ini
  echo ';mbstring.http_output_conv_mimetype=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[gd]' >> /tmp/php.ini
  echo '; Tell the jpeg decode to ignore warnings and try to create' >> /tmp/php.ini
  echo '; a gd image. The warning will then be displayed as notices' >> /tmp/php.ini
  echo '; disabled by default' >> /tmp/php.ini
  echo '; http://php.net/gd.jpeg-ignore-warning' >> /tmp/php.ini
  echo ';gd.jpeg_ignore_warning = 1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[exif]' >> /tmp/php.ini
  echo '; Exif UNICODE user comments are handled as UCS-2BE/UCS-2LE and JIS as JIS.' >> /tmp/php.ini
  echo '; With mbstring support this will automatically be converted into the encoding' >> /tmp/php.ini
  echo '; given by corresponding encode setting. When empty mbstring.internal_encoding' >> /tmp/php.ini
  echo '; is used. For the decode settings you can distinguish between motorola and' >> /tmp/php.ini
  echo '; intel byte order. A decode setting cannot be empty.' >> /tmp/php.ini
  echo '; http://php.net/exif.encode-unicode' >> /tmp/php.ini
  echo ';exif.encode_unicode = ISO-8859-15' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/exif.decode-unicode-motorola' >> /tmp/php.ini
  echo ';exif.decode_unicode_motorola = UCS-2BE' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/exif.decode-unicode-intel' >> /tmp/php.ini
  echo ';exif.decode_unicode_intel    = UCS-2LE' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/exif.encode-jis' >> /tmp/php.ini
  echo ';exif.encode_jis =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/exif.decode-jis-motorola' >> /tmp/php.ini
  echo ';exif.decode_jis_motorola = JIS' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; http://php.net/exif.decode-jis-intel' >> /tmp/php.ini
  echo ';exif.decode_jis_intel    = JIS' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[Tidy]' >> /tmp/php.ini
  echo '; The path to a default tidy configuration file to use when using tidy' >> /tmp/php.ini
  echo '; http://php.net/tidy.default-config' >> /tmp/php.ini
  echo ';tidy.default_config = /usr/local/lib/php/default.tcfg' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Should tidy clean and repair output automatically?' >> /tmp/php.ini
  echo '; WARNING: Do not use this option if you are generating non-html content' >> /tmp/php.ini
  echo '; such as dynamic images' >> /tmp/php.ini
  echo '; http://php.net/tidy.clean-output' >> /tmp/php.ini
  echo 'tidy.clean_output = Off' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[soap]' >> /tmp/php.ini
  echo '; Enables or disables WSDL caching feature.' >> /tmp/php.ini
  echo '; http://php.net/soap.wsdl-cache-enabled' >> /tmp/php.ini
  echo 'soap.wsdl_cache_enabled=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Sets the directory name where SOAP extension will put cache files.' >> /tmp/php.ini
  echo '; http://php.net/soap.wsdl-cache-dir' >> /tmp/php.ini
  echo 'soap.wsdl_cache_dir="/tmp"' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; (time to live) Sets the number of second while cached file will be used' >> /tmp/php.ini
  echo '; instead of original one.' >> /tmp/php.ini
  echo '; http://php.net/soap.wsdl-cache-ttl' >> /tmp/php.ini
  echo 'soap.wsdl_cache_ttl=86400' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Sets the size of the cache limit. (Max. number of WSDL files to cache)' >> /tmp/php.ini
  echo 'soap.wsdl_cache_limit = 5' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[sysvshm]' >> /tmp/php.ini
  echo '; A default size of the shared memory segment' >> /tmp/php.ini
  echo ';sysvshm.init_mem = 10000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[ldap]' >> /tmp/php.ini
  echo '; Sets the maximum number of open links or -1 for unlimited.' >> /tmp/php.ini
  echo 'ldap.max_links = -1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[mcrypt]' >> /tmp/php.ini
  echo '; For more information about mcrypt settings see http://php.net/mcrypt-module-open' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Directory where to load mcrypt algorithms' >> /tmp/php.ini
  echo '; Default: Compiled in into libmcrypt (usually /usr/local/lib/libmcrypt)' >> /tmp/php.ini
  echo ';mcrypt.algorithms_dir=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Directory where to load mcrypt modes' >> /tmp/php.ini
  echo '; Default: Compiled in into libmcrypt (usually /usr/local/lib/libmcrypt)' >> /tmp/php.ini
  echo ';mcrypt.modes_dir=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[dba]' >> /tmp/php.ini
  echo ';dba.default_handler=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[opcache]' >> /tmp/php.ini
  echo '; Determines if Zend OPCache is enabled' >> /tmp/php.ini
  echo 'opcache.enable=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Determines if Zend OPCache is enabled for the CLI version of PHP' >> /tmp/php.ini
  echo 'opcache.enable_cli=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The OPcache shared memory storage size.' >> /tmp/php.ini
  echo ';opcache.memory_consumption=128' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The amount of memory for interned strings in Mbytes.' >> /tmp/php.ini
  echo ';opcache.interned_strings_buffer=8' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The maximum number of keys (scripts) in the OPcache hash table.' >> /tmp/php.ini
  echo '; Only numbers between 200 and 100000 are allowed.' >> /tmp/php.ini
  echo ';opcache.max_accelerated_files=10000' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The maximum percentage of "wasted" memory until a restart is scheduled.' >> /tmp/php.ini
  echo ';opcache.max_wasted_percentage=5' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; When this directive is enabled, the OPcache appends the current working' >> /tmp/php.ini
  echo '; directory to the script key, thus eliminating possible collisions between' >> /tmp/php.ini
  echo '; files with the same name (basename). Disabling the directive improves' >> /tmp/php.ini
  echo '; performance, but may break existing applications.' >> /tmp/php.ini
  echo ';opcache.use_cwd=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; When disabled, you must reset the OPcache manually or restart the' >> /tmp/php.ini
  echo '; webserver for changes to the filesystem to take effect.' >> /tmp/php.ini
  echo ';opcache.validate_timestamps=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; How often (in seconds) to check file timestamps for changes to the shared' >> /tmp/php.ini
  echo '; memory storage allocation. ("1" means validate once per second, but only' >> /tmp/php.ini
  echo '; once per request. "0" means always validate)' >> /tmp/php.ini
  echo ';opcache.revalidate_freq=2' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enables or disables file search in include_path optimization' >> /tmp/php.ini
  echo ';opcache.revalidate_path=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If disabled, all PHPDoc comments are dropped from the code to reduce the' >> /tmp/php.ini
  echo '; size of the optimized code.' >> /tmp/php.ini
  echo ';opcache.save_comments=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If enabled, a fast shutdown sequence is used for the accelerated code' >> /tmp/php.ini
  echo '; Depending on the used Memory Manager this may cause some incompatibilities.' >> /tmp/php.ini
  echo ';opcache.fast_shutdown=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Allow file existence override (file_exists, etc.) performance feature.' >> /tmp/php.ini
  echo ';opcache.enable_file_override=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; A bitmask, where each bit enables or disables the appropriate OPcache' >> /tmp/php.ini
  echo '; passes' >> /tmp/php.ini
  echo ';opcache.optimization_level=0xffffffff' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo ';opcache.inherited_hack=1' >> /tmp/php.ini
  echo ';opcache.dups_fix=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; The location of the OPcache blacklist file (wildcards allowed).' >> /tmp/php.ini
  echo '; Each OPcache blacklist file is a text file that holds the names of files' >> /tmp/php.ini
  echo '; that should not be accelerated. The file format is to add each filename' >> /tmp/php.ini
  echo '; to a new line. The filename may be a full path or just a file prefix' >> /tmp/php.ini
  echo '; (i.e., /var/www/x  blacklists all the files and directories in /var/www' >> /tmp/php.ini
  echo '; that start with "x"). Line starting with a ; are ignored (comments).' >> /tmp/php.ini
  echo ';opcache.blacklist_filename=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Allows exclusion of large files from being cached. By default all files' >> /tmp/php.ini
  echo '; are cached.' >> /tmp/php.ini
  echo ';opcache.max_file_size=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Check the cache checksum each N requests.' >> /tmp/php.ini
  echo '; The default value of "0" means that the checks are disabled.' >> /tmp/php.ini
  echo ';opcache.consistency_checks=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; How long to wait (in seconds) for a scheduled restart to begin if the cache' >> /tmp/php.ini
  echo '; is not being accessed.' >> /tmp/php.ini
  echo ';opcache.force_restart_timeout=180' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; OPcache error_log file name. Empty string assumes "stderr".' >> /tmp/php.ini
  echo ';opcache.error_log=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; All OPcache errors go to the Web server log.' >> /tmp/php.ini
  echo '; By default, only fatal errors (level 0) or errors (level 1) are logged.' >> /tmp/php.ini
  echo '; You can also enable warnings (level 2), info messages (level 3) or' >> /tmp/php.ini
  echo '; debug messages (level 4).' >> /tmp/php.ini
  echo ';opcache.log_verbosity_level=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Preferred Shared Memory back-end. Leave empty and let the system decide.' >> /tmp/php.ini
  echo ';opcache.preferred_memory_model=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Protect the shared memory from unexpected writing during script execution.' >> /tmp/php.ini
  echo '; Useful for internal debugging only.' >> /tmp/php.ini
  echo ';opcache.protect_memory=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Allows calling OPcache API functions only from PHP scripts which path is' >> /tmp/php.ini
  echo '; started from specified string. The default "" means no restriction' >> /tmp/php.ini
  echo ';opcache.restrict_api=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Mapping base of shared memory segments (for Windows only). All the PHP' >> /tmp/php.ini
  echo '; processes have to map shared memory into the same address space. This' >> /tmp/php.ini
  echo '; directive allows to manually fix the "Unable to reattach to base address"' >> /tmp/php.ini
  echo '; errors.' >> /tmp/php.ini
  echo ';opcache.mmap_base=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enables and sets the second level cache directory.' >> /tmp/php.ini
  echo '; It should improve performance when SHM memory is full, at server restart or' >> /tmp/php.ini
  echo '; SHM reset. The default "" disables file based caching.' >> /tmp/php.ini
  echo ';opcache.file_cache=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enables or disables opcode caching in shared memory.' >> /tmp/php.ini
  echo ';opcache.file_cache_only=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enables or disables checksum validation when script loaded from file cache.' >> /tmp/php.ini
  echo ';opcache.file_cache_consistency_checks=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Implies opcache.file_cache_only=1 for a certain process that failed to' >> /tmp/php.ini
  echo '; reattach to the shared memory (for Windows only). Explicitly enabled file' >> /tmp/php.ini
  echo '; cache is required.' >> /tmp/php.ini
  echo ';opcache.file_cache_fallback=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Enables or disables copying of PHP code (text segment) into HUGE PAGES.' >> /tmp/php.ini
  echo '; This should improve performance, but requires appropriate OS configuration.' >> /tmp/php.ini
  echo ';opcache.huge_code_pages=1' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Validate cached file permissions.' >> /tmp/php.ini
  echo ';opcache.validate_permission=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Prevent name collisions in chroot"ed environment.' >> /tmp/php.ini
  echo ';opcache.validate_root=0' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[curl]' >> /tmp/php.ini
  echo '; A default value for the CURLOPT_CAINFO option. This is required to be an' >> /tmp/php.ini
  echo '; absolute path.' >> /tmp/php.ini
  echo ';curl.cainfo =' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '[openssl]' >> /tmp/php.ini
  echo '; The location of a Certificate Authority (CA) file on the local filesystem' >> /tmp/php.ini
  echo '; to use when verifying the identity of SSL/TLS peers. Most users should' >> /tmp/php.ini
  echo '; not specify a value for this directive as PHP will attempt to use the' >> /tmp/php.ini
  echo '; OS-managed cert stores in its absence. If specified, this value may still' >> /tmp/php.ini
  echo '; be overridden on a per-stream basis via the "cafile" SSL stream context' >> /tmp/php.ini
  echo '; option.' >> /tmp/php.ini
  echo ';openssl.cafile=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; If openssl.cafile is not specified or if the CA file is not found, the' >> /tmp/php.ini
  echo '; directory pointed to by openssl.capath is searched for a suitable' >> /tmp/php.ini
  echo '; certificate. This value must be a correctly hashed certificate directory.' >> /tmp/php.ini
  echo '; Most users should not specify a value for this directive as PHP will' >> /tmp/php.ini
  echo '; attempt to use the OS-managed cert stores in its absence. If specified,' >> /tmp/php.ini
  echo '; this value may still be overridden on a per-stream basis via the "capath"' >> /tmp/php.ini
  echo '; SSL stream context option.' >> /tmp/php.ini
  echo ';openssl.capath=' >> /tmp/php.ini
  echo '' >> /tmp/php.ini
  echo '; Local Variables:' >> /tmp/php.ini
  echo '; tab-width: 4' >> /tmp/php.ini
  echo '; End:' >> /tmp/php.ini
  
  mv /etc/php/7.1/fpm/php.ini /etc/php/7.1/fpm/php.ini-original
  mv /etc/php/7.1/cli/php.ini /etc/php/7.1/cli/php.ini-original
  cp /tmp/php.ini /etc/php/7.1/fpm/php.ini
  cp /tmp/php.ini /etc/php/7.1/cli/php.ini

  cd /tmp
  echo '' > /tmp/www.conf  
  echo '[www]' >> /tmp/www.conf
  echo '' >> /tmp/www.conf
  echo ';prefix = /path/to/pools/$pool' >> /tmp/www.conf
  echo 'user = www-data' >> /tmp/www.conf
  echo 'group = www-data' >> /tmp/www.conf
  echo 'listen = /var/run/php7.1-fpm.sock' >> /tmp/www.conf
  echo ';listen.backlog = 511' >> /tmp/www.conf
  echo 'listen.owner = www-data' >> /tmp/www.conf
  echo 'listen.group = www-data' >> /tmp/www.conf
  echo 'listen.mode = 0660' >> /tmp/www.conf
  echo ';listen.acl_users =' >> /tmp/www.conf
  echo ';listen.acl_groups =' >> /tmp/www.conf
  echo ';listen.allowed_clients = 127.0.0.1' >> /tmp/www.conf
  echo '; process.priority = -19' >> /tmp/www.conf
  echo '' >> /tmp/www.conf
  echo 'pm = dynamic' >> /tmp/www.conf
  echo 'pm.max_children = 10' >> /tmp/www.conf
  echo 'pm.start_servers = 2' >> /tmp/www.conf
  echo 'pm.min_spare_servers = 2' >> /tmp/www.conf
  echo 'pm.max_spare_servers = 8' >> /tmp/www.conf
  echo 'pm.process_idle_timeout = 10s;' >> /tmp/www.conf
  echo ';pm.max_requests = 500' >> /tmp/www.conf
  echo ';pm.status_path = /status' >> /tmp/www.conf
  echo ';ping.path = /ping' >> /tmp/www.conf
  echo ';ping.response = pong' >> /tmp/www.conf
  echo ';access.log = log/$pool.access.log' >> /tmp/www.conf
  echo ';access.format = "%R - %u %t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"' >> /tmp/www.conf
  echo ';slowlog = log/$pool.log.slow' >> /tmp/www.conf
  echo ';request_slowlog_timeout = 0' >> /tmp/www.conf
  echo ';request_terminate_timeout = 0' >> /tmp/www.conf
  echo ';rlimit_files = 1024' >> /tmp/www.conf
  echo ';rlimit_core = 0' >> /tmp/www.conf
  echo ';chroot =' >> /tmp/www.conf
  echo ';chdir = /var/www' >> /tmp/www.conf
  echo ';catch_workers_output = yes' >> /tmp/www.conf
  echo ';clear_env = no' >> /tmp/www.conf
  echo ';security.limit_extensions = .php .php3 .php4 .php5 .php7' >> /tmp/www.conf
  echo ';env[HOSTNAME] = $HOSTNAME' >> /tmp/www.conf
  echo ';env[PATH] = /usr/local/bin:/usr/bin:/bin' >> /tmp/www.conf
  echo ';env[TMP] = /tmp' >> /tmp/www.conf
  echo ';env[TMPDIR] = /tmp' >> /tmp/www.conf
  echo ';env[TEMP] = /tmp' >> /tmp/www.conf
  echo ';php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f www@my.domain.com' >> /tmp/www.conf
  echo 'php_flag[display_errors] = off' >> /tmp/www.conf
  echo 'php_admin_value[error_log] = /var/log/php/7.1/fpm-php.www.log' >> /tmp/www.conf
  echo 'php_admin_flag[log_errors] = on' >> /tmp/www.conf
  echo 'php_admin_value[memory_limit] = 32M' >> /tmp/www.conf

  mv /etc/php/7.1/fpm/pool.d/www.conf /etc/php/7.1/fpm/pool.d/www.conf-original
  cp www.conf /etc/php/7.1/fpm/pool.d/www.conf

  cd /tmp
  echo 'server {' >> /tmp/000default.conf
  echo '  charset       utf8;' >> /tmp/000default.conf
  echo '  listen        80;' >> /tmp/000default.conf
  echo '  server_name   localhost;' >> /tmp/000default.conf
  echo '  root          /usr/share/nginx/html;' >> /tmp/000default.conf
  echo '  index         index.html index.php;' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  error_page    404              /404.html;' >> /tmp/000default.conf
  echo '  error_page    500 502 503 504  /50x.html;' >> /tmp/000default.conf
  echo '  location = /50x.html { root   /usr/share/nginx/html; }' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  access_log  /dev/null gzip;' >> /tmp/000default.conf
  echo '  error_log   /dev/null notice;' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  location ~ [^/]\.php(/|$) {' >> /tmp/000default.conf
  echo '    if (!-f $document_root$fastcgi_script_name) { return 404; }' >> /tmp/000default.conf
  echo '    fastcgi_split_path_info     ^(.+?\.php)(/.*)$;' >> /tmp/000default.conf
  echo '    fastcgi_pass                unix:/var/run/php7.1-fpm.sock;' >> /tmp/000default.conf
  echo '    fastcgi_index               index.php;' >> /tmp/000default.conf
  echo '    include                     /etc/nginx/fastcgi_params;' >> /tmp/000default.conf
  echo '  }' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  include     /etc/nginx/security.conf;' >> /tmp/000default.conf
  echo '}' >> /tmp/000default.conf

  cp /tmp/000default.conf /etc/nginx/sites-enabled/

  # create the webroot workspaces
  mkdir -p /var/www
  chown -R www-data:www-data /var/www

  # restart the services
  service nginx restart && service php7.1-fpm restart
  
  ########################
  # install composer.phar#
  ########################

  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/bin/composer

fi

cd /tmp

########################################
# install MongoDB, RabbitMQ, Redis, Go #
########################################

apt install -y --force-yes mongodb-org rabbitmq-server redis-server redis-tools
systemctl enable mongod.service
service rabbitmq-server start

#############################################
# install (and configure) postgresql (!TODO)#
#############################################
if [ "$appserver_type" = '4' ]; then
  postgresql_root_password=$db_root_password
  apt install -y postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6 libpq-dev
fi

#############################################
# install (and configure) odoo9             #
#############################################

cd /tmp

if [ "$appserver_type" = '5' ]; then

  echo "Installing necessary python libraries"
  apt-get install -y --force-yes python-pybabel
  apt-get build-dep -y python-psycopg2
  pip install psycopg2 werkzeug simplejson
  apt-get install -y --force-yes python-dev python-cups python-dateutil python-decorator python-docutils python-feedparser \
                     python-gdata python-geoip python-gevent python-imaging python-jinja2 python-ldap python-libxslt1 \
                     python-mako python-mock python-openid python-passlib python-psutil python-psycopg2 \
                     python-pychart python-pydot python-pyparsing python-pypdf python-reportlab python-requests \
                     python-simplejson python-tz python-unicodecsv python-unittest2 python-vatnumber python-vobject \
                     python-werkzeug python-xlwt python-yaml

  echo "Installing wkhtmltopdf"
  cd /tmp
  wget http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz
  tar -xJf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz
  cd wkhtmltox
  rsync -avP * /usr
  cd /tmp
  rm -R wkhtmltox
  rm wkhtmltox-0.12.3_linux-generic-amd64.tar.xz
  
  echo "--------------------------------"
  echo ""
  echo "INSTALLING odoo v10........."
  echo ""
  echo "--------------------------------"
  
  cd /tmp

  postgresql_root_password=$db_root_password
  adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --gecos 'odoo' --group odoo

  echo "PostgreSQL 9.6"
  apt install -y postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6 libpq-dev postgresql-common
  echo "Create PostgreSQL User"
  sudo -u postgres -H createuser --createdb --username postgres --no-createrole --no-superuser odoo
  service postgresql start
  sudo -u postgres -H psql -c"ALTER user odoo WITH PASSWORD '$db_root_password'"
  service postgresql restart

  echo "Clone the Odoo 10 latest sources"
  cd /opt/odoo
  sudo -u odoo -H git clone https://github.com/OCA/OCB --depth 1 --branch 10.0 --single-branch .
  mkdir /opt/odoo/addons
  chown -R odoo:odoo /opt/odoo
  
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

  cd /opt/odoo
  easy_install --upgrade pip
  pip install -r requirements.txt
  pip install requests==2.6.0

  cd /tmp
  echo '#!/bin/sh' > /tmp/odoo10-server
  echo '### BEGIN INIT INFO' >> /tmp/odoo10-server
  echo '# Provides:             odoo-server' >> /tmp/odoo10-server
  echo '# Required-Start:       $remote_fs $syslog' >> /tmp/odoo10-server
  echo '# Required-Stop:        $remote_fs $syslog' >> /tmp/odoo10-server
  echo '# Should-Start:         $network' >> /tmp/odoo10-server
  echo '# Should-Stop:          $network' >> /tmp/odoo10-server
  echo '# Default-Start:        2 3 4 5' >> /tmp/odoo10-server
  echo '# Default-Stop:         0 1 6' >> /tmp/odoo10-server
  echo '# Short-Description:    Complete Business Application software' >> /tmp/odoo10-server
  echo '# Description:          Odoo is a complete suite of business tools.' >> /tmp/odoo10-server
  echo '### END INIT INFO' >> /tmp/odoo10-server
  echo 'PATH=/bin:/sbin:/usr/bin:/usr/local/bin' >> /tmp/odoo10-server
  echo 'DAEMON=/opt/odoo/odoo-bin' >> /tmp/odoo10-server
  echo 'NAME=odoo-server' >> /tmp/odoo10-server
  echo 'DESC=odoo-server' >> /tmp/odoo10-server
  echo '# Specify the user name (Default: odoo).' >> /tmp/odoo10-server
  echo 'USER=odoo' >> /tmp/odoo10-server
  echo '# Specify an alternate config file (Default: /etc/odoo-server.conf).' >> /tmp/odoo10-server
  echo 'CONFIGFILE="/etc/odoo-server.conf"' >> /tmp/odoo10-server
  echo '# pidfile' >> /tmp/odoo10-server
  echo 'PIDFILE=/var/run/$NAME.pid' >> /tmp/odoo10-server
  echo '# Additional options that are passed to the Daemon.' >> /tmp/odoo10-server
  echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> /tmp/odoo10-server
  echo '[ -x $DAEMON ] || exit 0' >> /tmp/odoo10-server
  echo '[ -f $CONFIGFILE ] || exit 0' >> /tmp/odoo10-server
  echo 'checkpid() {' >> /tmp/odoo10-server
  echo '    [ -f $PIDFILE ] || return 1' >> /tmp/odoo10-server
  echo '    pid=`cat $PIDFILE`' >> /tmp/odoo10-server
  echo '    [ -d /proc/$pid ] && return 0' >> /tmp/odoo10-server
  echo '    return 1' >> /tmp/odoo10-server
  echo '}' >> /tmp/odoo10-server
  echo 'case "${1}" in' >> /tmp/odoo10-server
  echo '        start)' >> /tmp/odoo10-server
  echo '                echo -n "Starting ${DESC}: "' >> /tmp/odoo10-server
  echo '                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> /tmp/odoo10-server
  echo '                        --chuid ${USER} --background --make-pidfile \' >> /tmp/odoo10-server
  echo '                        --exec ${DAEMON} -- ${DAEMON_OPTS}' >> /tmp/odoo10-server
  echo '                echo "${NAME}."' >> /tmp/odoo10-server
  echo '                ;;' >> /tmp/odoo10-server
  echo '        stop)' >> /tmp/odoo10-server
  echo '                echo -n "Stopping ${DESC}: "' >> /tmp/odoo10-server
  echo '                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> /tmp/odoo10-server
  echo '                        --oknodo' >> /tmp/odoo10-server
  echo '                echo "${NAME}."' >> /tmp/odoo10-server
  echo '                ;;' >> /tmp/odoo10-server
  echo '        restart|force-reload)' >> /tmp/odoo10-server
  echo '                echo -n "Restarting ${DESC}: "' >> /tmp/odoo10-server
  echo '                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> /tmp/odoo10-server
  echo '                        --oknodo' >> /tmp/odoo10-server
  echo '' >> /tmp/odoo10-server
  echo '                sleep 1' >> /tmp/odoo10-server
  echo '                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> /tmp/odoo10-server
  echo '                        --chuid ${USER} --background --make-pidfile \' >> /tmp/odoo10-server
  echo '                        --exec ${DAEMON} -- ${DAEMON_OPTS}' >> /tmp/odoo10-server
  echo '                echo "${NAME}."' >> /tmp/odoo10-server
  echo '                ;;' >> /tmp/odoo10-server
  echo '        *)' >> /tmp/odoo10-server
  echo '                N=/etc/init.d/${NAME}' >> /tmp/odoo10-server
  echo '                echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> /tmp/odoo10-server
  echo '                exit 1' >> /tmp/odoo10-server
  echo '                ;;' >> /tmp/odoo10-server
  echo 'esac' >> /tmp/odoo10-server
  echo 'exit 0' >> /tmp/odoo10-server

  cp /tmp/odoo10-server /etc/init.d/odoo-server
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
echo "************************************************************" > $install_summarize
echo "   DEBIAN JESSIE 8.7 PERFECT APPLICATION SERVER INSTALLER   " >> $install_summarize
echo "    -- proudly present by eRQee (q@codingaja.com) --        " >> $install_summarize
echo "                       *   *   *                            " >> $install_summarize
echo "                   INSTALL SUMMARIZE                        " >> $install_summarize
echo "************************************************************" >> $install_summarize
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
grunt_ver=$( grunt --version )
bower_ver=$( bower --version )
gulp_ver=$( gulp --version | grep "CLI" )
yeoman_ver=$( yo --version )

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
echo "NodeJS    : $node_ver" >> $install_summarize
echo "NPM       : $npm_ver" >> $install_summarize
echo "Grunt     : $grunt_ver" >> $install_summarize
echo "Bower     : $bower_ver" >> $install_summarize
echo "Gulp      : $gulp_ver" >> $install_summarize
echo "Yeoman    : $yeoman_ver" >> $install_summarize
echo "" >> $install_summarize
echo "*----------------------*" >> $install_summarize
echo "* This Server SSH Keys *" >> $install_summarize
echo "*----------------------*" >> $install_summarize
echo "please copy this into GitLab $git_user_name (a.k.a. $git_user_email) account" >> $install_summarize
echo "" >> $install_summarize
cat /root/.ssh/id_rsa.pub >> $install_summarize 2>&1
echo "" >> $install_summarize
echo "" >> $install_summarize
echo "***********************************************************" >> $install_summarize
echo "                           ENJOY                           " >> $install_summarize
echo "***********************************************************" >> $install_summarize
clear
cat $install_summarize
exit 0