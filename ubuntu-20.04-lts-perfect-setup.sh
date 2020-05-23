clear
##############
# Am I root? #
##############
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root.'
    echo 'Try re-run the script after switched to root account by type "sudo su"'
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
echo "    UBUNTU 20.04 LTS PERFECT APPLICATION SERVER INSTALLER     "
echo "**************************************************************"
echo ""
echo ""
echo "What kind of application server role do you want to apply?"
echo "1. Perfect Server for Nginx, Apache, PHP-FPM, and MariaDB"
echo "2. Dedicated Webserver (Nginx, Apache & PHP-FPM) only"
echo "3. Dedicated Database Server (MariaDB) only"
echo "4. Dedicated Database Server (PostgreSQL) only"
echo "5. Odoo Perfect Server (Nginx + Odoo + PostgrSQL)"
read -p "Your Choice (1/2/3/4/5) : " appserver_type

if [ "$appserver_type" != '2' ]; then
  echo ""
  read -p "Enter the default database root password: " db_root_password
fi

echo ""
echo "Enter your DevOps name/email below."
echo "The information will be used as this server's Git identity."
echo ""
read -p "DevOps Name : " git_user_name
read -p "DevOps Email : " git_user_email

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

repo=/etc/apt/sources.list
repo_address=kambing.ui.ac.id
mv $repo /etc/apt/sources.list.old && touch $repo
echo "deb http://$repo_address/ubuntu/ $(lsb_release -sc) main restricted universe multiverse" > $repo
echo "deb-src http://$repo_address/ubuntu/ $(lsb_release -sc) main restricted universe multiverse" >> $repo
echo "deb http://$repo_address/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_address/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiverse" >> $repo
echo "deb http://$repo_address/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_address/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse" >> $repo
echo "deb http://$repo_address/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_address/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse" >> $repo
echo "deb http://$repo_address/ubuntu/ $(lsb_release -sc)-proposed main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_address/ubuntu/ $(lsb_release -sc)-proposed main restricted universe multiverse" >> $repo

apt update && apt upgrade -y && apt install -y apt-transport-https debian-keyring gnupg2

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2'  ] || [ "$appserver_type" = '5' ]; then
  #nginx
  echo "deb http://nginx.org/packages/mainline/ubuntu $(lsb_release -sc) nginx" > /etc/apt/sources.list.d/nginx-mainline.list
  echo "deb-src http://nginx.org/packages/mainline/ubuntu $(lsb_release -sc) nginx" >> /etc/apt/sources.list.d/nginx-mainline.list
  curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
  #php
  echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/php-deb.sury.org.list
  echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/php-deb.sury.org.list
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C  
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  echo "deb [arch=amd64] http://mirror.biznetgio.com/mariadb/repo/10.5/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/mariadb-10.4.list
  echo "deb-src [arch=amd64] http://mirror.biznetgio.com/mariadb/repo/10.5/ubuntu $(lsb_release -sc) main" >> /etc/apt/sources.list.d/mariadb-10.4.list
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F1656F24C74CD1D8
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  echo "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" > /etc/apt/sources.list.d/postgresql.list
  echo "deb-src https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" >> /etc/apt/sources.list.d/postgresql.list
  wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
fi

echo "deb http://repos.azulsystems.com/ubuntu stable main" > /etc/apt/sources.list.d/zulu-openjdk-14.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xB1998361219BD9C9


###########################################################
# little configuration
###########################################################

mv /etc/localtime /etc/localtime.old
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

echo "root soft nofile 65536" >> /etc/security/limits.conf
echo "root hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 10240    65535" >> /etc/sysctl.conf

############################
#install essential packages#
############################

apt update && apt upgrade -y

apt install -y autoconf automake bison build-essential ca-certificates cdbs \
               certbot check chrpath debconf-utils devscripts dh-make fakeroot \
               flex fontconfig g++ gettext gperf imagemagick libbz2-dev \
               libcurl4-gnutls-dev libevent-dev libexpat1-dev libffi-dev \
               libfontconfig1-dev libgdbm-dev libgif-dev libicu-dev libjpeg-dev \
               libldap2-dev libmcrypt-dev libncurses5-dev libpcre3-dev libpng-dev \
               libreadline-dev libsasl2-dev libsqlite3-dev libssl-dev libtool \
               libx11-dev libxext-dev libxft-dev libxml-parser-perl libxml2-dev \
               libxrender-dev libxrender1 libxslt1-dev libyaml-dev locales-all \
               locate lynx net-tools openssh-server optipng p7zip-full pcregrep \
               pdftk poppler-utils ruby-full tcl traceroute unrar unzip uuid-dev \
               whois xfonts-75dpi xfonts-base xfonts-scalable zip zlib1g-dev zulu-14

locale-gen en_US en_US.UTF-8 id_ID id_ID.UTF-8

#############################
#configure mail notification#
#############################

update-ca-certificates
apt install -y msmtp-mta mailutils 

echo "defaults" > /etc/msmtprc
echo "  auth on" >> /etc/msmtprc
echo "  tls on" >> /etc/msmtprc
echo "  tls_trust_file /etc/ssl/certs/ca-certificates.crt" >> /etc/msmtprc
echo "  logfile /var/log/msmtp" >> /etc/msmtprc
echo "" >> /etc/msmtprc
echo "account default" >> /etc/msmtprc
echo "" >> /etc/msmtprc
echo "  host smtp.zoho.com" >> /etc/msmtprc
echo "  port 465" >> /etc/msmtprc
echo "" >> /etc/msmtprc
echo "  auth on" >> /etc/msmtprc
echo "  user commit@serverq.org" >> /etc/msmtprc
echo "  password Broadcastlah123..." >> /etc/msmtprc
echo "  from no-reply@serverq.org" >> /etc/msmtprc
echo "" >> /etc/msmtprc
echo "  tls on" >> /etc/msmtprc
echo "  tls_starttls off" >> /etc/msmtprc
echo "  tls_certcheck off" >> /etc/msmtprc

chmod 0640 /etc/msmtprc
touch /var/log/msmtp
chmod 666 /var/log/msmtp

echo 'set sendmail="/usr/bin/msmtp"' > /root/.mailrc
echo 'set use_from=yes' >> /root/.mailrc
echo 'set realname="ServerQ Notification"' >> /root/.mailrc
echo 'set from="no-reply@serverq.org"' >> /root/.mailrc
echo 'set envelope_from=yes' >> /root/.mailrc

systmctl restart msmtpd.service

apt install -y mutt
cp /root/.mailrc /root/.muttrc

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
  curl -sL https://deb.nodesource.com/setup_14.x | bash -
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  apt update && apt install -y nodejs yarn
  npm install -g npm@latest

  ################
  #install redis #
  ################
  apt install -y redis-server
  sed -i '/\<supervised no\>/c\supervised systemd' /etc/redis/redis.conf
  redis_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  sed -i "/# requirepass foobared/c\requirepass $redis_password" /etc/redis/redis.conf
  systemctl restart redis.service

fi

#################################
#install (and configure) mariadb#
#################################

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  export DEBIAN_FRONTEND=noninteractive
  echo "mariadb-server-10.5 mysql-server/root_password password $db_root_password" | sudo /usr/bin/debconf-set-selections
  echo "mariadb-server-10.5 mysql-server/root_password_again password $db_root_password" | sudo /usr/bin/debconf-set-selections
  apt install -y mariadb-server-10.5 mariadb-server-core-10.5 mariadb-client-10.5 mariadb-client-core-10.5 \
                 mariadb-plugin-connect mariadb-plugin-spider

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
  echo "query_cache_size          = 64      ## default: 64M" >> my.cnf
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
  echo "myisam_recover_options    = BACKUP" >> my.cnf
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
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Security Features" >> my.cnf
  echo "# chroot                  = /var/lib/mysql/" >> my.cnf
  echo "# ssl-ca                  = /etc/mysql/cacert.pem" >> my.cnf
  echo "# ssl-cert                = /etc/mysql/server-cert.pem" >> my.cnf
  echo "# ssl-key                 = /etc/mysql/server-key.pem" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Galera Replication" >> my.cnf
  echo "" >> my.cnf
  echo "[galera]" >> my.cnf
  echo "#report_host              = master1" >> my.cnf
  echo "#sync_binlog              = 1   ## not fab for performance, but safer" >> my.cnf
  echo "max_binlog_size           = 100M" >> my.cnf
  echo "expire_logs_days          = 10" >> my.cnf
  echo "binlog-format             = ROW" >> my.cnf
  echo "#wsrep_on                 = ON" >> my.cnf
  echo "#wsrep_provider           =" >> my.cnf
  echo "#wsrep_cluster_address    =" >> my.cnf
  echo "#wsrep_slave_threads      = 1" >> my.cnf
  echo "# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Extended Config" >> my.cnf
  echo '!include /etc/mysql/mariadb.cnf' >> my.cnf
  echo '!includedir /etc/mysql/conf.d/' >> my.cnf

  mv /etc/mysql/my.cnf /etc/mysql/my.cnf.original
  cp /tmp/my.cnf /etc/mysql/my.cnf

  # restart the services
  systemctl restart mariadb.service
  
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

  if [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
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
  echo "##---------------------------------------------##" >> /tmp/nginx.conf
  echo "# Last Update May 23, 2020  08:15 WIB by eRQee  #" >> /tmp/nginx.conf
  echo "##---------------------------------------------##" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "user                    www-data;" >> /tmp/nginx.conf
  cpu_core_count=$( nproc )
  echo "worker_processes        $cpu_core_count;" >> /tmp/nginx.conf
  echo "pid                     /run/nginx.pid;" >> /tmp/nginx.conf
  echo "include                 /etc/nginx/modules-enabled/*.conf;" >> /tmp/nginx.conf
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
  echo "    sendfile              on;" >> /tmp/nginx.conf
  echo "    tcp_nopush            on;" >> /tmp/nginx.conf
  echo "    tcp_nodelay           on;" >> /tmp/nginx.conf
  echo "    types_hash_max_size   2048;" >> /tmp/nginx.conf
  echo "    server_tokens         off;" >> /tmp/nginx.conf
  echo "    server_names_hash_bucket_size       512;" >> /tmp/nginx.conf
  echo "    server_name_in_redirect             off;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    gzip                  on;" >> /tmp/nginx.conf
  echo "    gzip_comp_level       2;" >> /tmp/nginx.conf
  echo "    gzip_min_length       1000;" >> /tmp/nginx.conf
  echo "    gzip_vary             on;" >> /tmp/nginx.conf
  echo "    gzip_proxied          any;" >> /tmp/nginx.conf
  echo "    gzip_buffers          16 8k;" >> /tmp/nginx.conf
  echo "    gzip_http_version     1.1;" >> /tmp/nginx.conf
  echo "    gzip_types            text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;" >> /tmp/nginx.conf
  echo "    gzip_disable          \"msie6\";" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    access_log            /dev/null main;" >> /tmp/nginx.conf
  echo "    error_log             /dev/null warn;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    keepalive_timeout     12;" >> /tmp/nginx.conf
  echo "    send_timeout          10;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    proxy_connect_timeout 60;" >> /tmp/nginx.conf
  echo "    proxy_send_timeout    60;" >> /tmp/nginx.conf
  echo "    proxy_read_timeout    60;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    client_max_body_size  100M;" >> /tmp/nginx.conf
  echo "    client_header_timeout 12;" >> /tmp/nginx.conf
  echo "    client_body_timeout   12;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    fastcgi_read_timeout  600;" >> /tmp/nginx.conf
  echo "    fastcgi_buffer_size   32k;" >> /tmp/nginx.conf
  echo "    fastcgi_buffers       16 16k;" >> /tmp/nginx.conf
  echo "    fastcgi_max_temp_file_size 0;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "    upstream apache    { server 127.0.0.1:77; }" >> /tmp/nginx.conf
  if [ "$appserver_type" = '5' ]; then
    echo "    upstream odoo      { server 127.0.0.1:8069; }" >> /tmp/nginx.conf
  fi
  echo "" >> /tmp/nginx.conf
  echo "    include /etc/nginx/conf.d/*.conf;" >> /tmp/nginx.conf
  echo "    include /etc/nginx/sites-enabled/*.conf;" >> /tmp/nginx.conf
  echo "" >> /tmp/nginx.conf
  echo "}" >> /tmp/nginx.conf

  mv /etc/nginx/nginx.conf /etc/nginx/nginx.original.conf
  cp /tmp/nginx.conf /etc/nginx/nginx.conf

  mkdir -p /etc/nginx/snippets

  cd /tmp
  echo "" > /tmp/security.conf
  echo '## Only requests to our Host are allowed' >> /tmp/security.conf
  echo '# if ($host !~ ^($server_name)$ ) { return 444; }' >> /tmp/security.conf
  echo '## Only allow these request methods' >> /tmp/security.conf
  echo 'if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE|OPTIONS)$ ) { return 444; }' >> /tmp/security.conf
  echo '## Deny certain Referers' >> /tmp/security.conf
  echo 'if ( $http_referer ~* (babes|love|nudit|poker|porn|sex) )  { return 404; return 403; }' >> /tmp/security.conf
  echo '## Cache the static contents' >> /tmp/security.conf
  echo 'location ~* ^.+.(jpg|jpeg|gif|png|ico|svg|woff|woff2|ttf|eot|txt|swf|mp4|ogg|flv|mp3|wav|mid|mkv|avi|3gp|webm|webp)$ { access_log off; expires max; }' >> /tmp/security.conf

  mv /tmp/security.conf /etc/nginx/snippets/security.conf

  mkdir -p /etc/nginx/certs
  wget -O /etc/nginx/certs/lets-encrypt-x3-cross-signed.pem "https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem"
  openssl dhparam -out /etc/nginx/certs/dhparam.pem 2048

  cd /tmp
  echo '' > /tmp/ssl-params.conf
  echo 'ssl_protocols             TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;' >> /tmp/ssl-params.conf
  echo 'ssl_session_cache         shared:le_nginx_SSL:10m;' >> /tmp/ssl-params.conf
  echo 'ssl_session_timeout       6h;' >> /tmp/ssl-params.conf
  echo 'ssl_session_tickets       on;' >> /tmp/ssl-params.conf
  echo '' >> /tmp/ssl-params.conf
  echo 'ssl_prefer_server_ciphers on;' >> /tmp/ssl-params.conf
  echo 'ssl_ciphers               "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS";' >> /tmp/ssl-params.conf
  echo 'ssl_ecdh_curve            secp521r1:secp384r1;' >> /tmp/ssl-params.conf
  echo 'ssl_dhparam               /etc/nginx/certs/dhparam.pem;' >> /tmp/ssl-params.conf
  echo '' >> /tmp/ssl-params.conf
  echo 'ssl_stapling              on;' >> /tmp/ssl-params.conf
  echo 'ssl_stapling_verify       on;' >> /tmp/ssl-params.conf
  echo 'resolver                  8.8.8.8 8.8.4.4 valid=300s;' >> /tmp/ssl-params.conf
  echo 'resolver_timeout          10s;' >> /tmp/ssl-params.conf
  echo 'ssl_trusted_certificate   /etc/nginx/certs/lets-encrypt-x3-cross-signed.pem;' >> /tmp/ssl-params.conf
  echo '' >> /tmp/ssl-params.conf
  echo 'add_header                Strict-Transport-Security "max-age=63072000; includeSubDomains" always;' >> /tmp/ssl-params.conf
  echo 'add_header                X-Frame-Options SAMEORIGIN;' >> /tmp/ssl-params.conf
  echo 'add_header                X-Content-Type-Options nosniff always;' >> /tmp/ssl-params.conf
  echo 'add_header                X-XSS-Protection "1; mode=block" always;' >> /tmp/ssl-params.conf

  mv /tmp/ssl-params.conf /etc/nginx/snippets/ssl-params.conf

  echo 'proxy_next_upstream     error timeout invalid_header http_500 http_502 http_503 http_504;' > /tmp/reverse-proxy.conf
  echo 'proxy_redirect          off;' >> /tmp/reverse-proxy.conf
  echo 'proxy_buffering         off;' >> /tmp/reverse-proxy.conf
  echo 'proxy_set_header        X-Forwarded-Proto       $scheme;' >> /tmp/reverse-proxy.conf
  echo 'proxy_set_header        Host                    $http_host;' >> /tmp/reverse-proxy.conf
  echo 'proxy_set_header        X-Forwarded-Host        $http_host;' >> /tmp/reverse-proxy.conf
  echo 'proxy_set_header        X-Real-IP               $remote_addr;' >> /tmp/reverse-proxy.conf
  echo 'proxy_set_header        X-Forwarded-For         $proxy_add_x_forwarded_for;' >> /tmp/reverse-proxy.conf
  echo 'proxy_set_header        X-Frame-Options         SAMEORIGIN;' >> /tmp/reverse-proxy.conf
  echo 'proxy_connect_timeout   60;' >> /tmp/reverse-proxy.conf
  echo 'proxy_send_timeout      60;' >> /tmp/reverse-proxy.conf
  echo 'proxy_read_timeout      60;' >> /tmp/reverse-proxy.conf
        
  mv /tmp/reverse-proxy.conf /etc/nginx/snippets/reverse-proxy.conf    

  mkdir -p /etc/nginx/sites-available
  mkdir -p /etc/nginx/sites-enabled

  echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/info.php

  cd /tmp
  echo 'server {' > /tmp/000default.conf
  echo '  charset                utf8;' >> /tmp/000default.conf
  echo '  listen                 80;' >> /tmp/000default.conf
  echo '  listen                 [::]:80;' >> /tmp/000default.conf
  echo '  server_name            nginx.vbox;' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  access_log             /dev/null gzip;' >> /tmp/000default.conf
  echo '  error_log              /dev/null notice;' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  root                   /usr/share/nginx/html;' >> /tmp/000default.conf
  echo '  index                  info.php index.php index.html;' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  error_page             404              /404.html;' >> /tmp/000default.conf
  echo '  error_page             500 502 503 504  /50x.html;' >> /tmp/000default.conf
  echo '  location  =           /50x.html { root  /usr/share/nginx/html; }' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  # location / { try_files $uri $uri/ /index.php$is_args$args; }  ## enable this line if you use PHP framework' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  location ~ [^/]\.php(/|$) {' >> /tmp/000default.conf
  echo '    if (!-f $document_root$fastcgi_script_name) { return 404; }' >> /tmp/000default.conf
  echo '    fastcgi_split_path_info ^(.+?\.php)(/.*)$;' >> /tmp/000default.conf
  echo '    ## [alternative] ##  fastcgi_split_path_info ^(.+\.php)(/.+)$;' >> /tmp/000default.conf
  echo '    fastcgi_pass         unix:/var/run/php7.4-fpm.sock;' >> /tmp/000default.conf
  echo '    fastcgi_index        index.php;' >> /tmp/000default.conf
  echo '    include              /etc/nginx/fastcgi_params;' >> /tmp/000default.conf
  echo '    fastcgi_param        SCRIPT_FILENAME  $document_root$fastcgi_script_name;' >> /tmp/000default.conf
  echo '    fastcgi_param        PATH_INFO        $fastcgi_path_info;' >> /tmp/000default.conf
  echo '    fastcgi_param        PATH_TRANSLATED  $document_root$fastcgi_path_info;' >> /tmp/000default.conf
  echo '  }' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  location ~ /\.ht { deny all; }' >> /tmp/000default.conf
  echo '' >> /tmp/000default.conf
  echo '  include     /etc/nginx/snippets/security.conf;' >> /tmp/000default.conf
  echo '  client_max_body_size   20M;' >> /tmp/000default.conf
  echo '}' >> /tmp/000default.conf

  mv /tmp/000default.conf /etc/nginx/sites-available/000default.conf
  ln -s /etc/nginx/sites-available/000default.conf /etc/nginx/sites-enabled/000default.conf

  echo 'server {' > /tmp/000default-ssl.conf
  echo '  charset                utf8;' >> /tmp/000default-ssl.conf
  echo '  listen                 80;' >> /tmp/000default-ssl.conf
  echo '  listen                 [::]:80;' >> /tmp/000default-ssl.conf
  echo '  server_name            nginx.vbox;' >> /tmp/000default-ssl.conf
  echo '  return 302             https://$server_name$request_uri;' >> /tmp/000default-ssl.conf
  echo '}' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo 'server {' >> /tmp/000default-ssl.conf
  echo '  listen                 443 ssl http2' >> /tmp/000default-ssl.conf
  echo '  listen                 [::]:443 ssl http2' >> /tmp/000default-ssl.conf
  echo '  server_name            nginx.vbox;' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo '  access_log	         /dev/null gzip;' >> /tmp/000default-ssl.conf
  echo '  error_log	             /dev/null notice;' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo '  ssl_certificate        /etc/letsencrypt/live/nginx.vbox/fullchain.pem;' >> /tmp/000default-ssl.conf
  echo '  ssl_certificate_key    /etc/letsencrypt/live/nginx.vbox/privkey.pem;' >> /tmp/000default-ssl.conf
  echo '  include                /etc/nginx/snippets/ssl-params.conf' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo '  root                   /var/www/nginx.vbox/;' >> /tmp/000default-ssl.conf
  echo '  index                  index.php index.html;' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo '  error_page             404              /404.html;' >> /tmp/000default-ssl.conf
  echo '  error_page             500 502 503 504  /50x.html;' >> /tmp/000default-ssl.conf
  echo '  location            = /50x.html { root  /var/www/nginx.vbox/; }' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo '  # location / { try_files $uri $uri/ /index.php$is_args$args; }  ## enable this line if you use PHP framework' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo '  location ~ [^/]\.php(/|$) {' >> /tmp/000default-ssl.conf
  echo '    if (!-f $document_root$fastcgi_script_name) { return 404; }' >> /tmp/000default-ssl.conf
  echo '    fastcgi_split_path_info ^(.+?\.php)(/.*)$;' >> /tmp/000default-ssl.conf
  echo '    ## [alternative] ##  fastcgi_split_path_info ^(.+\.php)(/.+)$;' >> /tmp/000default-ssl.conf
  echo '    fastcgi_pass         unix:/var/run/php7.4-fpm.sock;' >> /tmp/000default-ssl.conf
  echo '    fastcgi_index        index.php;' >> /tmp/000default-ssl.conf
  echo '    include              /etc/nginx/fastcgi_params;' >> /tmp/000default-ssl.conf
  echo '    fastcgi_param        SCRIPT_FILENAME  $document_root$fastcgi_script_name;' >> /tmp/000default-ssl.conf
  echo '    fastcgi_param        PATH_INFO        $fastcgi_path_info;' >> /tmp/000default-ssl.conf
  echo '    fastcgi_param        PATH_TRANSLATED  $document_root$fastcgi_path_info;' >> /tmp/000default-ssl.conf
  echo '    fastcgi_param        HTTPS            $https if_not_empty;' >> /tmp/000default-ssl.conf
  echo '  }' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo '  location ~ /\.ht { deny all; }' >> /tmp/000default-ssl.conf
  echo '  location /.well-known/acme-challenge/ { root /usr/share/nginx/html; log_not_found off; }' >> /tmp/000default-ssl.conf
  echo '' >> /tmp/000default-ssl.conf
  echo '  include                /etc/nginx/snippets/security.conf;' >> /tmp/000default-ssl.conf
  echo '  client_max_body_size   20M;' >> /tmp/000default-ssl.conf
  echo '}' >> /tmp/000default-ssl.conf

  mv /tmp/000default.conf /etc/nginx/sites-available/000default-ssl.conf

  echo 'server {' > /tmp/000default-ssl-reverse-proxy.conf
  echo '  charset                utf8;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  listen                 80;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  listen                 [::]:80;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  server_name            nginx.vbox;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  return 302             https://$server_name$request_uri;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '}' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '' >> /tmp/000default-ssl-reverse-proxy.conf
  echo 'server {' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  listen                 443 ssl http2' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  listen                 [::]:443 ssl http2' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  server_name            nginx.vbox;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  access_log	         /dev/null gzip;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  error_log	             /dev/null notice;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  ssl_certificate        /etc/letsencrypt/live/nginx.vbox/fullchain.pem;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  ssl_certificate_key    /etc/letsencrypt/live/nginx.vbox/privkey.pem;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  include                /etc/nginx/snippets/ssl-params.conf' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  root                   /var/www/nginx.vbox/;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  location / {' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '    proxy_pass              http://apache;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '    error_page              502 = /502.html;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '    include                 /etc/nginx/snippets/reverse-proxy.conf;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '    send_timeout            60;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '    client_max_body_size    100M;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '    client_body_buffer_size 100M;' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '  }' >> /tmp/000default-ssl-reverse-proxy.conf
  echo '}' >> /tmp/000default-ssl-reverse-proxy.conf

  mv /tmp/000default-ssl-reverse-proxy.conf /etc/nginx/sites-available/000default-ssl-reverse-proxy.conf

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
  sed -i '/;sendmail_path/c\sendmail_path = "/usr/bin/msmtp -C /etc/msmtprc -a -t"' /tmp/php.ini-serverq.recommended

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
  systemctl stop nginx.service
  apt install -y apache2
  a2enmod actions alias deflate expires headers http2 negotiation proxy proxy_fcgi proxy_http2 reflector remoteip rewrite setenvif substitute vhost_alias
  
  this_server_name="$(hostname).apache"
  sed -i "/#ServerRoot/a ServerName $this_server_name" /etc/apache2/apache2.conf
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
  systemctl restart apache2.service
  systemctl restart nginx.service
  systemctl restart php7.4-fpm

  # normalize the /etc/hosts values
  echo '127.0.0.1       localhost' > /etc/hosts
  echo '' >> /etc/hosts
  echo '# VirtualHost addresses.' >> /etc/hosts
  echo '# Normally you do not need to register all of your project addresses here.' >> /etc/hosts
  echo '# You must configure this on your client /etc/hosts or via your DNS Resolver' >> /etc/hosts
  echo '' >> /etc/hosts
  echo '127.0.0.1       nginx.vbox   apache.vbox' >> /etc/hosts
  echo '' >> /etc/hosts
  echo '' >> /etc/hosts
  echo '' >> /etc/hosts
  echo '# The following lines are desirable for IPv6 capable hosts' >> /etc/hosts
  echo '::1             localhost ip6-localhost ip6-loopback' >> /etc/hosts
  echo 'ff02::1         ip6-allnodes' >> /etc/hosts
  echo 'ff02::2         ip6-allrouters' >> /etc/hosts
  
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
if [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  apt install -y postgresql-12 postgresql-client-12 postgresql-contrib-12 postgresql-server-dev-12 libpq-dev

  if [ "$appserver_type" = '4' ]; then
    mkdir -p /home/enterprise
    adduser --system --quiet --shell=/bin/bash --home=/home/enterprise --gecos 'enterprise' --group enterprise
    chown -R enterprise:enterprise /home/enterprise
    echo "Create PostgreSQL EnterpriseDB User (enterprise)"
    sudo -u postgres -H createuser --createdb --username postgres --no-createrole --no-superuser enterprise
    service postgresql start
    sudo -u postgres -H psql -c"ALTER user enterprise WITH PASSWORD '$db_root_password'"
    service postgresql restart
  fi
  
fi

#############################################
# install (and configure) odoo13            #
#############################################

cd /tmp

if [ "$appserver_type" = '5' ]; then

  echo "Installing necessary python libraries"
  apt install -y python3-pip python3-setuptools python3-dev
  pip3 install babel psycopg2 werkzeug simplejson pillow lxml cups \
               dateutil decorator docutils feedparser geoip gevent \
               jinja2 ldap mako mock openid passlib psutil pydot \
               pyparsing reportlab requests tz unicodecsv unittest2 \
               vatnumber vobject yaml
      
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
  echo " INSTALLING odoo v13 ..........."
  echo " Ref: https://www.73lines.com/blog/erp-5/post/how-to-install-odoo13-on-ubuntu-20-04-x64-lts-36"
  echo "--------------------------------"
  
  cd /tmp
  adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --gecos 'odoo' --group odoo
  mkdir /etc/odoo && mkdir /var/log/odoo/

  echo "Create PostgreSQL User"
  sudo -u postgres -H createuser --createdb --username postgres --no-createrole --no-superuser odoo
  service postgresql start
  sudo -u postgres -H psql -c"ALTER user odoo WITH PASSWORD '$db_root_password'"
  service postgresql restart

  echo "Clone the Odoo 13 latest sources"
  cd /opt/odoo
  sudo -u odoo -H git clone https://github.com/odoo/odoo --depth 1 --branch 13.0 --single-branch .
  mkdir /opt/odoo/addons
  chown -R odoo:odoo /opt/odoo
  chown -R odoo:odoo /var/log/odoo/
  
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
  npm install -g less less-plugin-clean-css rtlcss generator-feathers graceful-fs@^4.0.0 yo minimatch@^3.0.2 -y
  pip3 install -r requirements.txt
  pip3 install requests==2.6.0

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
public_ip=$( curl https://ifconfig.me/ip  )
mail_subject="Server $public_ip installed with Ubuntu 20.04 LTS!"
echo "Well done!" > /tmp/mail-body.txt 
echo "You've finished the Ubuntu 20.04 LTS installation on server $public_ip at $timestamp_flag." >> /tmp/mail-body.txt 
echo "" >> /tmp/mail-body.txt
echo "Please review and keep the attached install summarize report below." >> /tmp/mail-body.txt 
echo "*************************************************************" > $install_summarize
echo "    UBUNTU 20.04 LTS PERFECT APPLICATION SERVER INSTALLER    " >> $install_summarize
echo "       -- present by eRQee (rizky@prihanto.web.id)  --       " >> $install_summarize
echo "                         *   *   *                           " >> $install_summarize
echo "                     INSTALL SUMMARIZE                       " >> $install_summarize
echo "************************************************************" >> $install_summarize
echo "" >> $install_summarize
echo "Done installing at $timestamp_flag" >> $install_summarize
echo "Using repo http://$repo_address" >> $install_summarize
echo "" >> $install_summarize
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ]  || [ "$appserver_type" = '5' ]; then
  nginx_ver=$(nginx -v 2>&1)
  apache_ver=$(apache2ctl -v | grep "version")
  php_ver=$(php -v | grep "(cli)")
  echo "[Web Server Information]"  >> $install_summarize
  echo "$nginx_ver" >> $install_summarize
  echo "$apache_ver" >> $install_summarize
  echo "$php_ver" >> $install_summarize
  echo "" >> $install_summarize
fi
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ]  || [ "$appserver_type" = '5' ]; then
  mysql_ver=$(mysql --version)
  mysqltuner_ver=$(mysqltuner --test | grep "High Performance Tuning Script" 2>&1)
  echo "[MariaDB Information]" >> $install_summarize
  echo "$mysql_ver" >> $install_summarize
  echo "MariaDB root Password : $db_root_password" >> $install_summarize
  echo "MySQLTuner : $mysqltuner_ver (installed at /scripts/mysqltuner/mysqltuner.pl)" >> $install_summarize
  echo "" >> $install_summarize
fi
if [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  pgsql_ver=$(psql --version)
  echo "[PostgreSQL Information]" >> $install_summarize
  echo "$pgsql_ver" >> $install_summarize
  echo "PostgreSQL postgres Password : $db_root_password" >> $install_summarize
  if [ "$appserver_type" = '4' ]; then
    echo "User / Password : enterprise / $db_odoo_password" >> $install_summarize
  fi
  if [ "$appserver_type" = '5' ]; then
    echo "User / Password : odoo / $db_odoo_password" >> $install_summarize
  fi
fi
echo "" >> $install_summarize
git_ver=$(git --version)
echo "[Git Information]"  >> $install_summarize
echo "$git_ver" >> $install_summarize
git config --list >> $install_summarize 2>&1
echo "" >> $install_summarize
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ]  || [ "$appserver_type" = '5' ]; then
  node_ver=$(node -v)
  npm_ver=$(npm -v)
  yarn_ver=$(yarn -v)
  redis_ver=$(redis-cli -v)
  echo "[NodeJS]"  >> $install_summarize
  echo "NodeJS    : $node_ver" >> $install_summarize
  echo "NPM       : $npm_ver" >> $install_summarize
  echo "YARN      : $yarn_ver" >> $install_summarize
  echo ""  >> $install_summarize
  echo "[REDIS]"  >> $install_summarize
  echo "Version   : $redis_ver" >> $install_summarize
  echo "Password  : $redis_password" >> $install_summarize
fi
echo "" >> $install_summarize
echo "*----------------------*" >> $install_summarize
echo "* This Server SSH Keys *" >> $install_summarize
echo "*----------------------*" >> $install_summarize
echo "please copy this into Code.SQ $git_user_name (a.k.a. $git_user_email) account" >> $install_summarize
echo "" >> $install_summarize
cat /root/.ssh/id_rsa.pub >> $install_summarize 2>&1
echo "" >> $install_summarize
echo "" >> $install_summarize
echo "***********************************************************" >> $install_summarize
echo "                           ENJOY                           " >> $install_summarize
echo "***********************************************************" >> $install_summarize
cat $install_summarize
timestamp_flag=` date +%F-%H-%M-%S`
mail_attachment=/root/install-log-$timestamp_flag.txt 
rm $mail_attachment
cp $install_summarize $mail_attachment
mutt -a $mail_attachment -s $mail_subject -- $git_user_email < /tmp/mail-body.txt
rm $mail_attachment
rm /tmp/mail-body.txt
exit 0
