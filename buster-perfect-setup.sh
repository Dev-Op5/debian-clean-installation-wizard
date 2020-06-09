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
echo "**************************************************************"
echo "   DEBIAN BUSTER 10.x PERFECT APPLICATION SERVER INSTALLER    "
echo "   -- proudly present by eRQee (rizky@prihanto.web.id)  --    "
echo "**************************************************************"
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
# choose preferred repository list
if [ -f /etc/apt/sources.list.old ]; then
  rm /etc/apt/sources.list.old
fi
mv $repo /etc/apt/sources.list.old && touch $repo

repo=/etc/apt/sources.list
repo_address=kartolo.sby.datautama.net.id

echo "deb http://$repo_address/debian/ $(lsb_release -sc) main non-free contrib" > $repo
echo "deb-src http://$repo_address/debian/ $(lsb_release -sc) main non-free contrib" >> $repo
echo "deb http://$repo_address/debian/ $(lsb_release -sc)-updates main non-free contrib" >> $repo
echo "deb-src http://$repo_address/debian/ $(lsb_release -sc)-updates main non-free contrib" >> $repo
echo "deb http://$repo_address/debian-security/ $(lsb_release -sc)/updates main non-free contrib" >> $repo
echo "deb-src http://$repo_address/debian-security/ $(lsb_release -sc)/updates main non-free contrib" >> $repo

apt update && apt install -y curl wget apt-transport-https ca-certificates lsb-release software-properties-common ed debian-keyring

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2'  ] || [ "$appserver_type" = '5' ]; then
  #nginx
  echo "deb http://nginx.org/packages/mainline/debian/ $(lsb_release -sc) nginx" > /etc/apt/sources.list.d/nginx-mainline.list
  echo "deb-src http://nginx.org/packages/mainline/debian/ $(lsb_release -sc) nginx" >> /etc/apt/sources.list.d/nginx-mainline.list
  wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
  #php
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php-deb.sury.org.list
  wget --no-check-certificate --quiet -O - https://packages.sury.org/php/apt.gpg | apt-key add - 
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  echo "deb [arch=amd64] http://mirror.biznetgio.com/mariadb/repo/10.4/debian $(lsb_release -sc) main" > /etc/apt/sources.list.d/mariadb-10.4.list
  echo "deb-src [arch=amd64] http://mirror.biznetgio.com/mariadb/repo/10.4/debian $(lsb_release -sc) main" >> /etc/apt/sources.list.d/mariadb-10.4.list
  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  echo "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" > /etc/apt/sources.list.d/postgresql.list
  echo "deb-src https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" >> /etc/apt/sources.list.d/postgresql.list
  wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
fi

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
#install essential packages#
############################

apt install -y build-essential unzip unrar sudo locate rsync hdparm net-tools git p7zip-full module-assistant openssh-server tor zip \
               autoconf automake libtool pdftk imagemagick tcpdump traceroute libaio1 tcpdump traceroute bash-completion certbot gettext \
               tcl locales-all libssl-dev libexpat1-dev libcurl4-gnutls-dev zlib1g-dev libasound2 libasound2-data whois lynx openssl \
               python perl libmcrypt-dev pcregrep gawk cdbs devscripts dh-make libxml-parser-perl check python-pip libbz2-dev libpcre3-dev \
               libxml2-dev unixodbc-bin sysv-rc-conf uuid-dev libicu-dev libncurses5-dev libffi-dev debconf-utils libgif-dev libevent-dev \
               chrpath libfontconfig1-dev libxft-dev optipng g++ fakeroot libyaml-dev libgdbm-dev libreadline-dev libxslt1-dev ruby-full \
               gperf bison g++ libsqlite3-dev libfreetype6 xfonts-scalable poppler-utils libxrender-dev xfonts-base xfonts-75dpi fontconfig \
               libxrender1 libldap2-dev libsasl2-dev flex bison libicu-dev libpng-dev libjpeg-dev python libxext-dev libx11-dev wkhtmltopdf

locale-gen en_US en_US.UTF-8 id_ID id_ID.UTF-8

###############
#configure git#
###############
ssh-keygen -t rsa -C "$git_user_email" -N "" -f ~/.ssh/id_rsa
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

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ] || [ "$appserver_type" = '5' ]; then

  ################
  #install nodejs#
  ################
  curl -sL https://deb.nodesource.com/setup_13.x | bash -
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  apt update && apt install -y nodejs yarn
  npm install -g npm@latest 
  npm install -g grunt-cli parcel webpack less less-plugin-clean-css generator-feathers graceful-fs@^4.0.0 yo minimatch@^3.0.2

  ###################
  # install java-13 #
  ###################
  cd /tmp
  wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" \
https://download.oracle.com/otn-pub/java/jdk/13.0.2+8/d4173c853231432d94f001e99d882ca7/jdk-13.0.2_linux-x64_bin.deb
  dpkg -i jdk-13.0.2_linux-x64_bin.deb
  echo "JAVA_HOME=\"/usr/lib/jvm/jdk-13.0.2\"" >> /etc/environment
  echo "PATH=$PATH:\"/usr/lib/jvm/jdk-13.0.2/bin\"" >> /etc/environment
  echo "J2SDKDIR=\"/usr/lib/jvm/jdk-13.0.2\"" >> /etc/environment
  echo "J2REDIR=\"/usr/lib/jvm/jdk-13.0.2\"" >> /etc/environment
  source /etc/environment
  rm /tmp/jdk-13.0.2_linux-x64_bin.deb
fi

#################################
#install (and configure) mariadb#
#################################

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  export DEBIAN_FRONTEND=noninteractive
  echo "mariadb-server-10.4 mysql-server/root_password password $db_root_password" | sudo /usr/bin/debconf-set-selections
  echo "mariadb-server-10.4 mysql-server/root_password_again password $db_root_password" | sudo /usr/bin/debconf-set-selections
  apt install -y mariadb-server-10.4 mariadb-server-core-10.4 mariadb-client-10.4 mariadb-client-core-10.4 \
                 mariadb-plugin-connect mariadb-plugin-cracklib-password-check mariadb-plugin-gssapi-server \
                 mariadb-plugin-gssapi-client mariadb-plugin-oqgraph mariadb-plugin-mroonga mariadb-plugin-spider 

  # reconfigure my.cnf
  cd /tmp
  echo "" > my.cnf
  echo "# MariaDB database server configuration file." >> my.cnf
  echo "# Configured template by eRQee (rizky@prihanto.web.id)" >> my.cnf
  echo "# -------------------------------------------------------------------------------" >> my.cnf
  echo "" >> my.cnf
  echo "[client]" >> my.cnf
  echo "port                      = 3306" >> my.cnf
  echo "socket                    = /var/run/mysqld/mysqld.sock" >> my.cnf
  echo "default-character-set     = utf8mb4" >> my.cnf
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
  echo "init_connect              = 'SET collation_connection=utf8mb4_unicode_ci; SET NAMES utf8mb4;'" >> my.cnf
  echo "character_set_server      = utf8mb4" >> my.cnf
  echo "collation_server          = utf8mb4_unicode_ci" >> my.cnf
  echo "character-set-server      = utf8mb4" >> my.cnf
  echo "collation-server          = utf8mb4_unicode_ci" >> my.cnf
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
  echo '!include /etc/mysql/mariadb.cnf' >> my.cnf
  echo '!includedir /etc/mysql/conf.d/' >> my.cnf

  mv /etc/mysql/my.cnf /etc/mysql/my.cnf.original
  cp /tmp/my.cnf /etc/mysql/my.cnf

  # restart the services
  service mysql restart
  
  #mysqltuner
  mkdir -p /scripts/mysqltuner
  cd /scripts/mysqltuner
  wget http://mysqltuner.pl/ -O mysqltuner.pl
  wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O basic_passwords.txt
  wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv -O vulnerabilities.csv
  chmod +x /scripts/mysqltuner/mysqltuner.pl
  echo "alias mysqltuner='/scripts/mysqltuner/mysqltuner.pl --cvefile=/scripts/mysqltuner/vulnerabilities.csv --passwordfile=/scripts/mysqltuner/basic_passwords.txt'" >> /etc/bash.bashrc
  cd /tmp
fi


##########################################
#install (and configure) nginx & php-fpm#
##########################################
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ] || [ "$appserver_type" = '5' ]; then
 
  apt install -y php7.4 php7.4-bcmath php7.4-bz2 php7.4-cgi php7.4-cli php7.4-common php7.4-curl php7.4-dba php7.4-dev php7.4-enchant \
                 php7.4-fpm php7.4-gd php7.4-gmp php7.4-imap php7.4-interbase php7.4-intl php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql \
                 php7.4-odbc php7.4-opcache php7.4-pgsql php7.4-pspell php7.4-readline php7.4-snmp php7.4-soap php7.4-sqlite3 php7.4-sybase \
                 php7.4-tidy php7.4-xml php7.4-xmlrpc php7.4-xsl php7.4-zip php-mongodb php-geoip libgeoip-dev snmp-mibs-downloader nginx

  if [ "$appserver_type" = '5' ]; then
    apt install -y libpq-dev
  fi

  # configuring nginx
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
  echo "fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;" >> /tmp/fastcgi_params
  echo "fastcgi_param  PATH_INFO          \$fastcgi_path_info;" >> /tmp/fastcgi_params
  echo "fastcgi_param  PATH_TRANSLATED    \$document_root\$fastcgi_path_info;" >> /tmp/fastcgi_params
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
  echo "    upstream apache    { server 127.0.0.1:77; }" >> /tmp/nginx.conf
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

  cp /tmp/security.conf /etc/nginx/security.conf

  cd /tmp
    echo 'server {' >> /tmp/000default.conf
    echo '  charset       utf8;' >> /tmp/000default.conf
    echo '  listen        80;' >> /tmp/000default.conf
    echo '  server_name   nginx.vbox;' >> /tmp/000default.conf
    echo '  root          /usr/share/nginx/html;' >> /tmp/000default.conf
    echo '  index         info.php index.php index.html;' >> /tmp/000default.conf
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
    echo '    fastcgi_pass                unix:/var/run/php7.4-fpm.sock;' >> /tmp/000default.conf
    echo '    fastcgi_index               index.php;' >> /tmp/000default.conf
    echo '    include                     /etc/nginx/fastcgi_params;' >> /tmp/000default.conf
    echo '  }' >> /tmp/000default.conf
    echo '' >> /tmp/000default.conf
    echo '  include     /etc/nginx/security.conf;' >> /tmp/000default.conf
    echo '}' >> /tmp/000default.conf

  echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/info.php

  mkdir -p /etc/nginx/sites-enabled
  mv /tmp/000default.conf /etc/nginx/sites-enabled/000default.conf

  # configuring php7.4-fpm
  mkdir -p /var/lib/php/7.4/sessions
  chmod -R 777 /var/lib/php/7.4/sessions

  cp /etc/php/7.4/fpm/php.ini /tmp/php.ini-serverq.recommended
  sed -i '/post_max_size/c\post_max_size = 100M' /tmp/php.ini-serverq.recommended
  sed -i '/;cgi.fix_pathinfo/c\cgi.fix_pathinfo=1' /tmp/php.ini-serverq.recommended
  sed -i '/;upload_tmp_dir/c\upload_tmp_dir=/tmp' /tmp/php.ini-serverq.recommended
  sed -i '/upload_max_filesize/c\upload_max_filesize=64M' /tmp/php.ini-serverq.recommended
  sed -i '/;date.timezone/c\date.timezone=Asia/Jakarta' /tmp/php.ini-serverq.recommended
  sed -i '/;date.default_latitude/c\date.default_latitude = -6.211544' /tmp/php.ini-serverq.recommended
  sed -i '/;date.default_longitude/c\date.default_longitude = 106.84517200000005' /tmp/php.ini-serverq.recommended
  sed -i '/;session.save_path/c\session.save_path = "/var/lib/php/7.4/sessions"' /tmp/php.ini-serverq.recommended  
  sed -i '/;opcache.enable=1/c\opcache.enable=1' /tmp/php.ini-serverq.recommended
  sed -i '/;opcache.enable_cli=0/c\opcache.enable_cli=1' /tmp/php.ini-serverq.recommended

  mv /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini-original
  mv /etc/php/7.4/cli/php.ini /etc/php/7.4/cli/php.ini-original
  cp /tmp/php.ini-serverq.recommended /etc/php/7.4/php.ini-serverq.recommended
  cp /tmp/php.ini-serverq.recommended /etc/php/7.4/fpm/php.ini
  cp /tmp/php.ini-serverq.recommended /etc/php/7.4/cli/php.ini

  cp /etc/php/7.4/fpm/pool.d/www.conf /tmp/www.conf-serverq.recommended
  sed -i '/listen = /run/php/php7.4-fpm.sock/c\listen = /var/run/php7.4-fpm.sock' /tmp/www.conf-serverq.recommended
  sed -i '/;listen.mode = 0660/c\listen.mode = 0660' /tmp/www.conf-serverq.recommended
  sed -i '/pm.max_children/c\pm.max_children = 10' /tmp/www.conf-serverq.recommended
  sed -i '/pm.min_spare_servers/c\pm.min_spare_servers = 2' /tmp/www.conf-serverq.recommended
  sed -i '/pm.max_spare_servers/c\pm.max_spare_servers = 8' /tmp/www.conf-serverq.recommended
  
  mv /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/www.conf-original
  cp /tmp/www.conf-serverq.recommended /etc/php/7.4/fpm/pool.d/www.conf-serverq.recommended
  cp /tmp/www.conf-serverq.recommended /etc/php/7.4/fpm/pool.d/www.conf

  # create the webroot workspaces
  mkdir -p /var/www/
  chown -R www-data:www-data /var/www/

  # create secondary webserver instance (Apache) that runs in port 77 (HTTP) and 7447 (HTTP/SSL)
  systemctl stop nginx
  apt install -y apache2
  a2enmod actions alias deflate expires headers http2 negotiation proxy proxy_fcgi proxy_http2 reflector remoteip rewrite setenvif substitute vhost_alias

  sed -i '/Listen 80/c\Listen 77' /etc/apache2/ports.conf
  sed -i '/Listen 443/c\Listen 7447' /etc/apache2/ports.conf

  echo '<VirtualHost *:77>' > /etc/apache2/sites-available/000-default.conf
  echo '    ServerName apache.vbox' >> /etc/apache2/sites-available/000-default.conf
  echo '    DocumentRoot /var/www/html' >> /etc/apache2/sites-available/000-default.conf
  echo '' >> /etc/apache2/sites-available/000-default.conf
  echo '    <Directory /var/www/html>' >> /etc/apache2/sites-available/000-default.conf
  echo '        Options -Indexes +FollowSymLinks +MultiViews' >> /etc/apache2/sites-available/000-default.conf
  echo '        AllowOverride All' >> /etc/apache2/sites-available/000-default.conf
  echo '        Require all granted' >> /etc/apache2/sites-available/000-default.conf
  echo '    </Directory>' >> /etc/apache2/sites-available/000-default.conf
  echo ' ' >> /etc/apache2/sites-available/000-default.conf
  echo '    <FilesMatch \.php$>' >> /etc/apache2/sites-available/000-default.conf
  echo '        SetHandler "proxy:unix:/var/run/php7.4-fpm.sock|fcgi://localhost"' >> /etc/apache2/sites-available/000-default.conf
  echo '    </FilesMatch>' >> /etc/apache2/sites-available/000-default.conf
  echo ' ' >> /etc/apache2/sites-available/000-default.conf
  echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf
  echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf
  echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf



  # restart the services
  systemctl restart nginx
  systemctl restart php7.4-fpm

  # normalize the /etc/hosts values
  echo '127.0.0.1       localhost' > /etc/hosts
  echo '' >> /etc/hosts
  echo '# VirtualHost addresses.' >> /etc/hosts
  echo '# Normally you do not need to register all of your project addresses here.' >> /etc/hosts
  echo '# You must configure this on your client /etc/hosts or via your DNS Server' >> /etc/hosts
  echo '' >> /etc/hosts
  echo '127.0.0.1       nginx.vbox   apache.vbox' >> /etc/hosts
  echo '' >> /etc/hosts
  echo '' >> /etc/hosts
  echo '' >> /etc/hosts
  echo '# The following lines are desirable for IPv6 capable hosts' >> /etc/hosts
  echo '::1     localhost ip6-localhost ip6-loopback' >> /etc/hosts
  echo 'ff02::1 ip6-allnodes' >> /etc/hosts
  echo 'ff02::2 ip6-allrouters' >> /etc/hosts
  
  ########################
  # install composer.phar#
  ########################

  cd /tmp
  curl -sS https://getcomposer.org/installer | php
  chmod +x composer.phar
  mv composer.phar /usr/local/bin/composer

fi

cd /tmp

#############################################
# install (and configure) postgresql        #
#############################################
if [ "$appserver_type" = '4' ]; then
  apt install -y postgresql-12 postgresql-client-12 postgresql-contrib-12 libpq-dev
  
fi

#############################################
# install (and configure) odoo12            #
#############################################

cd /tmp

if [ "$appserver_type" = '5' ]; then

  echo "Installing necessary python libraries"
  apt-get install -y python-pybabel
  apt-get build-dep -y python-psycopg2
  pip install psycopg2 werkzeug simplejson
  apt-get install -y python-dev python-cups python-dateutil python-decorator python-docutils python-feedparser \
                     python-gdata python-geoip python-gevent python-imaging python-jinja2 python-ldap python-libxslt1 \
                     python-mako python-mock python-openid python-passlib python-psutil python-psycopg2 \
                     python-pychart python-pydot python-pyparsing python-pypdf python-reportlab python-requests \
                     python-simplejson python-tz python-unicodecsv python-unittest2 python-vatnumber python-vobject \
                     python-werkzeug python-xlwt python-yaml

  echo "Installing wkhtmltopdf"
  cd /tmp
  wget http://download.gna.org/wkhtmltopdf/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
  tar -xJf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
  cd wkhtmltox
  rsync -avP * /usr
  cd /tmp
  rm -R wkhtmltox
  rm wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
  
  echo "--------------------------------"
  echo ""
  echo "INSTALLING odoo v12........."
  echo ""
  echo "--------------------------------"
  
  cd /tmp

  postgresql_root_password=$db_root_password
  adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --gecos 'odoo' --group odoo

  echo "PostgreSQL 11"
  apt install -y postgresql-11 postgresql-client-11 postgresql-contrib-11 libpq-dev postgresql-common
  echo "Create PostgreSQL User"
  sudo -u postgres -H createuser --createdb --username postgres --no-createrole --no-superuser odoo
  service postgresql start
  sudo -u postgres -H psql -c"ALTER user odoo WITH PASSWORD '$db_root_password'"
  service postgresql restart

  echo "Clone the Odoo 10 latest sources"
  cd /opt/odoo
  sudo -u odoo -H git clone https://github.com/odoo/odoo --depth 1 --branch 12.0 --single-branch .
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
  echo '#!/bin/sh' > /tmp/odoo-server
  echo '### BEGIN INIT INFO' >> /tmp/odoo-server
  echo '# Provides:             odoo-server' >> /tmp/odoo-server
  echo '# Required-Start:       $remote_fs $syslog' >> /tmp/odoo-server
  echo '# Required-Stop:        $remote_fs $syslog' >> /tmp/odoo-server
  echo '# Should-Start:         $network' >> /tmp/odoo-server
  echo '# Should-Stop:          $network' >> /tmp/odoo-server
  echo '# Default-Start:        2 3 4 5' >> /tmp/odoo-server
  echo '# Default-Stop:         0 1 6' >> /tmp/odoo-server
  echo '# Short-Description:    Complete Business Application software' >> /tmp/odoo-server
  echo '# Description:          Odoo is a complete suite of business tools.' >> /tmp/odoo-server
  echo '### END INIT INFO' >> /tmp/odoo-server
  echo 'PATH=/bin:/sbin:/usr/bin:/usr/local/bin' >> /tmp/odoo-server
  echo 'DAEMON=/opt/odoo/odoo-bin' >> /tmp/odoo-server
  echo 'NAME=odoo-server' >> /tmp/odoo-server
  echo 'DESC=odoo-server' >> /tmp/odoo-server
  echo '# Specify the user name (Default: odoo).' >> /tmp/odoo-server
  echo 'USER=odoo' >> /tmp/odoo-server
  echo '# Specify an alternate config file (Default: /etc/odoo-server.conf).' >> /tmp/odoo-server
  echo 'CONFIGFILE="/etc/odoo-server.conf"' >> /tmp/odoo-server
  echo '# pidfile' >> /tmp/odoo-server
  echo 'PIDFILE=/var/run/$NAME.pid' >> /tmp/odoo-server
  echo '# Additional options that are passed to the Daemon.' >> /tmp/odoo-server
  echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> /tmp/odoo-server
  echo '[ -x $DAEMON ] || exit 0' >> /tmp/odoo-server
  echo '[ -f $CONFIGFILE ] || exit 0' >> /tmp/odoo-server
  echo 'checkpid() {' >> /tmp/odoo-server
  echo '    [ -f $PIDFILE ] || return 1' >> /tmp/odoo-server
  echo '    pid=`cat $PIDFILE`' >> /tmp/odoo-server
  echo '    [ -d /proc/$pid ] && return 0' >> /tmp/odoo-server
  echo '    return 1' >> /tmp/odoo-server
  echo '}' >> /tmp/odoo-server
  echo 'case "${1}" in' >> /tmp/odoo-server
  echo '        start)' >> /tmp/odoo-server
  echo '                echo -n "Starting ${DESC}: "' >> /tmp/odoo-server
  echo '                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> /tmp/odoo-server
  echo '                        --chuid ${USER} --background --make-pidfile \' >> /tmp/odoo-server
  echo '                        --exec ${DAEMON} -- ${DAEMON_OPTS}' >> /tmp/odoo-server
  echo '                echo "${NAME}."' >> /tmp/odoo-server
  echo '                ;;' >> /tmp/odoo-server
  echo '        stop)' >> /tmp/odoo-server
  echo '                echo -n "Stopping ${DESC}: "' >> /tmp/odoo-server
  echo '                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> /tmp/odoo-server
  echo '                        --oknodo' >> /tmp/odoo-server
  echo '                echo "${NAME}."' >> /tmp/odoo-server
  echo '                ;;' >> /tmp/odoo-server
  echo '        restart|force-reload)' >> /tmp/odoo-server
  echo '                echo -n "Restarting ${DESC}: "' >> /tmp/odoo-server
  echo '                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> /tmp/odoo-server
  echo '                        --oknodo' >> /tmp/odoo-server
  echo '' >> /tmp/odoo-server
  echo '                sleep 1' >> /tmp/odoo-server
  echo '                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> /tmp/odoo-server
  echo '                        --chuid ${USER} --background --make-pidfile \' >> /tmp/odoo-server
  echo '                        --exec ${DAEMON} -- ${DAEMON_OPTS}' >> /tmp/odoo-server
  echo '                echo "${NAME}."' >> /tmp/odoo-server
  echo '                ;;' >> /tmp/odoo-server
  echo '        *)' >> /tmp/odoo-server
  echo '                N=/etc/init.d/${NAME}' >> /tmp/odoo-server
  echo '                echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> /tmp/odoo-server
  echo '                exit 1' >> /tmp/odoo-server
  echo '                ;;' >> /tmp/odoo-server
  echo 'esac' >> /tmp/odoo-server
  echo 'exit 0' >> /tmp/odoo-server

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
echo "*************************************************************" > $install_summarize
echo "   DEBIAN STRETCH 9.x PERFECT APPLICATION SERVER INSTALLER   " >> $install_summarize
echo "   -- proudly present by eRQee (rizky@prihanto.web.id)  --   " >> $install_summarize
echo "                         *   *   *                           " >> $install_summarize
echo "                     INSTALL SUMMARIZE                       " >> $install_summarize
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
