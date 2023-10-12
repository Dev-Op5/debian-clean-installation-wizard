#!/bin/bash

export PATH=$PATH:/sbin

# temporarily disable ipv6
/sbin/sysctl -w net.ipv6.conf.all.disable_ipv6=1
/sbin/sysctl -w net.ipv6.conf.default.disable_ipv6=1

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
lsb_deb_version=$( dpkg --status tzdata|grep Provides|cut -f2 -d'-' )
str_arch=$(dpkg --print-architecture)
if [ -f $install_summarize ]; then
  clear
  cat $install_summarize
  exit 0
fi

echo ""
echo "****************************************************************"
echo "   DEBIAN ${lsb_deb_version} PERFECT APPLICATION SERVER INSTALLER    "
echo "    -- proudly present by eRQee (rizky@prihanto.web.id)  --     "
echo "****************************************************************"
echo ""
echo ""
echo "What kind of application server role do you want to apply?"
echo "1. Perfect Server for Nginx, PHP-FPM, and MariaDB"
echo "2. Dedicated Nginx & PHP-FPM Web Server only"
echo "3. Dedicated MariaDB Database Server only"
echo "4. Dedicated PostgreSQL Database Server only"
echo "5. Odoo 15 Perfect Server"
read -p "Your Choice (1/2/3/4/5) : " appserver_type

if [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  echo ""
  read -p "Enter the default database root password: " db_root_password
fi

echo ""
echo "Enter ZOHO Email Account Credentials below"
echo "~ this will be used for *will-not-be-marked-as-spam* mail notification services among your apps ~"
echo "~ leave empty to disable the MAIL features ~"
echo ""
read -p "Mail Account : " zoho_mail_account
if [ ! -z "$zoho_mail_account" ]; then
  read -p "Password : " zoho_mail_password
  read -p "Mail From Alias : " zoho_mail_from
fi
echo ""
echo "Enter your DevOps name/email below."
echo "~ the information will be used as this server's Git identity ~"
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

apt install -y apt-transport-https ca-certificates curl debian-keyring dirmngr ed gnupg gnupg1 gnupg2 lsb-release p7zip-full software-properties-common unzip zip

repo=/etc/apt/sources.list
repo_address=deb.debian.org

if [ -f /etc/apt/sources.list.old ]; then
  rm /etc/apt/sources.list.old
fi
mv $repo /etc/apt/sources.list.old && touch $repo

cat > $repo << EOL
deb http://${repo_address}/debian/ ${lsb_deb_version} main non-free non-free-firmware contrib
deb-src http://${repo_address}/debian/ ${lsb_deb_version} main non-free non-free-firmware contrib
deb http://${repo_address}/debian/ ${lsb_deb_version}-updates main non-free non-free-firmware contrib
deb-src http://${repo_address}/debian/ ${lsb_deb_version}-updates main non-free non-free-firmware contrib
deb http://security.debian.org/debian-security/ ${lsb_deb_version}-security main non-free non-free-firmware contrib
deb-src http://security.debian.org/debian-security/ ${lsb_deb_version}-security main non-free non-free-firmware contrib
EOL

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2'  ] || [ "$appserver_type" = '5' ]; then
  #nginx
  str_keyring=/etc/apt/trusted.gpg.d/nginx-archive-keyring.gpg
  wget --no-check-certificate --quiet -O - https://packages.sury.org/nginx-mainline/apt.gpg | gpg --dearmor | tee $str_keyring >/dev/null
  echo "deb [arch=$str_arch signed-by=$str_keyring] https://packages.sury.org/nginx-mainline/ $lsb_deb_version main" > /etc/apt/sources.list.d/nginx-mainline.list
  #php
  str_keyring=/etc/apt/trusted.gpg.d/php-archive-keyring.gpg
  wget --no-check-certificate --quiet -O - https://packages.sury.org/php/apt.gpg | gpg --dearmor | tee $str_keyring >/dev/null
  echo "deb [arch=$str_arch signed-by=$str_keyring] https://packages.sury.org/php/ $lsb_deb_version main" > /etc/apt/sources.list.d/php-deb.sury.org.list
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then
  str_keyring=/etc/apt/trusted.gpg.d/mariadb-archive-keyring.pgp
  wget --no-check-certificate --quiet -O - https://mariadb.org/mariadb_release_signing_key.pgp | tee $str_keyring >/dev/null
  echo "deb [arch=$str_arch signed-by=$str_keyring] https://suro.ubaya.ac.id/mariadb/repo/11.1/debian/ $lsb_deb_version main" > /etc/apt/sources.list.d/mariadb.list
fi

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  str_keyring=/etc/apt/trusted.gpg.d/postgresql-archive-keyring.gpg
  wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee ${str_keyring} >/dev/null
  echo "deb [arch=$str_arch signed-by=$str_keyring] https://apt.postgresql.org/pub/repos/apt/ $lsb_deb_version-pgdg main" > /etc/apt/sources.list.d/postgresql.list
  echo "deb-src [arch=$str_arch signed-by=$str_keyring] https://apt.postgresql.org/pub/repos/apt/ $lsb_deb_version-pgdg main" >> /etc/apt/sources.list.d/postgresql.list
fi


###########################################################
# system configuration
###########################################################

mv /etc/localtime /etc/localtime.old
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# change filesystem's file limit to the max
cat >> /etc/security/limits.conf << EOL
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536
EOL

# tuning up the IPv4 port registration capabilities
cat >> /etc/sysctl.conf << EOL
vm.swappiness = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240    65535
# for 1 GigE, increase this to 2500
# for 10 GigE, increase this to 30000
net.core.netdev_max_backlog = 2500

EOL

# prioritize IPv4 over IPv6 rather than completely disable the IPv6 support.
cat >> /etc/gai.conf << EOL
precedence ::ffff:0:0/96  100
scopev4 ::ffff:169.254.0.0/112  2
scopev4 ::ffff:127.0.0.0/104    2
scopev4 ::ffff:0.0.0.0/96       14
EOL

############################
#install essential packages#
############################

apt update && apt upgrade -y

echo "Breakpoint #1 : will install essentials packages, mail, git, and some scripts"
read -p "Press any key to continue..." any_key

apt install -y acl certbot dnsutils git hdparm libsqlite3-dev libtool locales-all locate lynx module-assistant \
               net-tools openssl optipng pcregrep python3-pip rsync sudo tcpdump traceroute uuid-dev whois \
               imagemagick pdftk wkhtmltopdf 

/sbin/locale-gen en_US en_US.UTF-8 id_ID id_ID.UTF-8
/usr/bin/localedef -i en_US -f UTF-8 en_US.UTF-8

#############################
#configure mail notification#
#############################

/sbin/update-ca-certificates

if [ ! -z "$zoho_mail_account" ]; then

  if [ ! -z "$zoho_mail_from" ]; then
    zoho_mail_from=$zoho_mail_account
  fi
  apt install -y msmtp-mta mailutils

cat > /etc/msmtprc << EOL
defaults
  auth on
  tls on
  tls_trust_file /etc/ssl/certs/ca-certificates.crt
  logfile /var/log/msmtp.log
account default
  host smtp.zoho.com
  port 465
  auth on
  user ${zoho_mail_account}
  password ${zoho_mail_password}
  from ${zoho_mail_from}
  tls on
  tls_starttls off
  tls_certcheck off
EOL

  chmod 0640 /etc/msmtprc
  touch /var/log/msmtp.log
  chmod 666 /var/log/msmtp.log

cat > /root/.mailrc << EOL
set sendmail=/usr/bin/msmtp
set use_from=yes
set realname="Mail Notification"
set from="${zoho_mail_from}"
set envelope_from=yes
EOL

  systemctl restart msmtpd.service

  apt install -y mutt
  cp /root/.mailrc /root/.muttrc
fi

###############
#configure git#
###############
if [ ! -z "$git_user_email" ]; then
  ssh-keygen -t rsa -C "$git_user_email" -N "" -f ~/.ssh/id_rsa
  git config --global user.name "$git_user_name"
  git config --global user.email "$git_user_email"
  git config --global core.editor nano
  git config --global color.ui true

  echo "" >> /etc/bash.bashrc
  echo "alias commit='git add --all . && git commit -m'" >> /etc/bash.bashrc
  echo "alias push='git push -u origin'" >> /etc/bash.bashrc
  echo "alias pull='git pull origin'" >> /etc/bash.bashrc
fi

###############################
#configure automation & checks#
###############################

mkdir -p /scripts/secure-poweroff
cd /scripts/secure-poweroff

cat > /scripts/secure-poweroff/poweroff << 'EOL'
#!/bin/bash
if [ "x$(id -u)" != 'x0' ]; then
  echo 'Error: this script can only be executed by root'
  exit 1
fi

read -p "You launched command to shutdown this machine. Are you serious? (Y/N) : " confirm_answer

if [ "$confirm_answer" = 'Y' ] || [ "$confirm_answer" = 'y' ]; then
  /sbin/poweroff
fi

exit 0
EOL
chmod +x /scripts/secure-poweroff/poweroff

cat > /scripts/secure-poweroff/reboot << 'EOL'
#!/bin/bash
if [ "x$(id -u)" != 'x0' ]; then
  echo 'Error: this script can only be executed by root'
  exit 1
fi

read -p "You launched command to reboot this machine. Are you serious? (Y/N) : " confirm_answer

if [ "$confirm_answer" = 'Y' ] || [ "$confirm_answer" = 'y' ]; then
  /sbin/reboot
fi

exit 0
EOL
chmod +x /scripts/secure-poweroff/reboot

echo "" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc
echo "alias sedot='wget --recursive --page-requisites --html-extension --convert-links --no-parent --random-wait -r -p -E -e robots=off'" >> /etc/bash.bashrc
echo "alias cp='rsync -ravz --progress'" >> /etc/bash.bashrc
echo "alias mkdir='mkdir -pv'" >> /etc/bash.bashrc
echo "alias wget='wget -c'" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc
echo "alias poweroff='/scripts/secure-poweroff/poweroff'" >> /etc/bash.bashrc
echo "alias reboot='/scripts/secure-poweroff/reboot'" >> /etc/bash.bashrc

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ] || [ "$appserver_type" = '5' ]; then

echo "Breakpoint #2 : will install node.js & redis"
read -p "Press any key to continue..." any_key

  ################
  #install nodejs#
  ################
  str_keyring=/etc/apt/trusted.gpg.d/nodesource-archive-keyring.gpg
  wget --no-check-certificate --quiet -O - https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor |  tee $str_keyring >/dev/null
  NODE_MAJOR=20
  echo "deb [signed-by=$str_keyring] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

  str_keyring=/etc/apt/trusted.gpg.d/yarn-archive-keyring.gpg
  wget --no-check-certificate --quiet -O - https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor |  tee $str_keyring >/dev/null
  echo "deb [arch=$str_arch signed-by=$str_keyring] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

  apt update && apt install -y nodejs yarn
  npm install -g npm@latest
  # install some cool server-administratives packages
  npm install -g degit vtop

fi

#################################
#install (and configure) mariadb#
#################################

if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '3' ] || [ "$appserver_type" = '5' ]; then

echo "Breakpoint #3 : will install mariadb database"
read -p "Press any key to continue..." any_key

  apt install -y mariadb-server mariadb-server-core mariadb-client mariadb-client-core \
                 mariadb-plugin-connect mariadb-plugin-cracklib-password-check

  # plugins that (commonly) will not installed:
  # mariadb-plugin-gssapi-server mariadb-plugin-gssapi-client mariadb-plugin-oqgraph mariadb-plugin-mroonga mariadb-plugin-rocksdb mariadb-plugin-s3 mariadb-plugin-spider mariadb-plugin-columnstore 

  # reconfigure my.cnf
  mkdir -p /tmp/mariadb.config

  MARIADB_SYSTEMD_CONFIG_DIR=/etc/mysql/mariadb.conf.d
  zip -r /etc/mysql/0riginal.config.zip $MARIADB_SYSTEMD_CONFIG_DIR
  cp -r $MARIADB_SYSTEMD_CONFIG_DIR /etc/mysql/0riginal.mariadb.conf.d

  cd /tmp/mariadb.config

cat > $MARIADB_SYSTEMD_CONFIG_DIR/50-client.cnf << EOL
# MariaDB database server configuration file.
# Configured template by eRQee (rizky@prihanto.web.id)
# -------------------------------------------------------------------------------
#
# This group is read by the client library
# Use it for options that affect all clients, but not the server
#

[client]
port                      = 3306
socket                    = /var/run/mysqld/mysqld.sock
default-character-set     = utf8mb4

# Default is Latin1, if you need UTF-8 set this (also in server section)

# Example of client certificate usage
# ssl-ca                  = /etc/mysql/cacert.pem
# ssl-cert                = /etc/mysql/server-cert.pem
# ssl-key                 = /etc/mysql/server-key.pem

# Allow only TLS encrypted connections
# ssl-verify-server-cert  = on

# This group is *never* read by mysql client library, though this
# /etc/mysql/mariadb.cnf.d/client.cnf file is not read by Oracle MySQL
# client anyway.
# If you use the same .cnf file for MySQL and MariaDB,
# use it for MariaDB-only client options

[client-mariadb]

EOL

cat > $MARIADB_SYSTEMD_CONFIG_DIR/50-mariadb-clients.cnf << EOL
# MariaDB database server configuration file.
# Configured template by eRQee (rizky@prihanto.web.id)
# -------------------------------------------------------------------------------
#

# These groups are read by MariaDB command-line tools
# Use it for options that affect only one utility
#

[mariadb-client]
socket                    = /var/run/mysqld/mysqld.sock
no-auto-rehash
local-infile

[mariadb-upgrade]

[mariadb-admin]

[mariadb-binlog]

[mariadb-check]

[mariadb-dump]
quick
quote-names
max_allowed_packet        = 1024M

[mariadb-import]

[mariadb-show]

[mariadb-slap]

EOL

cat > $MARIADB_SYSTEMD_CONFIG_DIR/50-mariadb_safe.cnf << EOL
# MariaDB database server configuration file.
# Configured template by eRQee (rizky@prihanto.web.id)
# -------------------------------------------------------------------------------
#
# NOTE: THIS FILE IS READ ONLY BY THE TRADITIONAL SYSV INIT SCRIPT, NOT SYSTEMD.
# MARIADB SYSTEMD DOES _NOT_ UTILIZE MYSQLD_SAFE NOR READ THIS FILE.
#
# For similar behavior, systemd users should create the following file:
# /etc/systemd/system/mariadb.service.d/migrated-from-my.cnf-settings.conf
#
# To achieve the same result as the default 50-mysqld_safe.cnf, please create
# /etc/systemd/system/mariadb.service.d/migrated-from-my.cnf-settings.conf
# with the following contents:
#
# [Service]
# User=mysql
# StandardOutput=syslog
# StandardError=syslog
# SyslogFacility=daemon
# SyslogLevel=err
# SyslogIdentifier=mariadbd
#
# For more information, please read https://mariadb.com/kb/en/mariadb/systemd/

[mariadbd-safe]
# This will be passed to all mysql clients
# It has been reported that passwords should be enclosed with ticks/quotes
# especially if they contain "#" chars...
#
socket                    = /var/run/mysqld/mysqld.sock
nice                      = 0
skip_log_error
syslog

EOL

cfg_binded_address=127.0.0.1
if [ "$appserver_type" = '3' ]; then
  cfg_binded_address=0.0.0.0
fi

memfree=$( less /proc/meminfo | grep MemFree )
set -- $( echo $memfree )
ibbuffer=$((${2}/2000))

cat > $MARIADB_SYSTEMD_CONFIG_DIR/50-server.cnf << EOL
# MariaDB database server configuration file.
# Configured template by eRQee (rizky@prihanto.web.id)
# -------------------------------------------------------------------------------
# 
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see

# this is read by the standalone daemon and embedded servers
[server]

[mysqld]
# ------------------------------------------------------------------------------- : SERVER PROFILE
server_id                 = 1
bind-address              = ${cfg_binded_address}
port                      = 3306
socket                    = /var/run/mysqld/mysqld.sock
pid-file                  = /var/run/mysqld/mysqld.pid
user                      = mysql
sql_mode                  = NO_ENGINE_SUBSTITUTION,TRADITIONAL

# ------------------------------------------------------------------------------- : PATH
basedir                   = /usr
datadir                   = /var/lib/mysql
tmpdir                    = /tmp
general_log_file          = /var/log/mysql/mariadb.log
log_error                 = /var/log/mysql/mariadb.err
log_bin                   = /var/log/mysql/mariadb-bin.log
log_bin_index             = /var/log/mysql/mariadb-bin.index
log_slow_query_file       = /var/log/mysql/mariadb-slow.log
#relay_log                = /var/log/mysql/relay-bin.log
#relay_log_index          = /var/log/mysql/relay-bin.index
#relay_log_info_file      = /var/log/mysql/relay-bin.info

# ------------------------------------------------------------------------------- : LOCALE SETTING
lc_messages_dir           = /usr/share/mysql
lc_messages               = en_US
init_connect              = 'SET collation_connection=utf8mb4_unicode_ci; SET NAMES utf8mb4;'
character_set_server      = utf8mb4
collation_server          = utf8mb4_unicode_ci
character-set-server      = utf8mb4
collation-server          = utf8mb4_unicode_ci
skip-character-set-client-handshake

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : GENERIC FEATURES
big_tables                = 1
event_scheduler           = 1
performance_schema        = 1
group_concat_max_len      = 268435456
skip-external-locking     = 1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : CONNECTION SETTING
max_connections           = 100
connect_timeout           = 60
wait_timeout              = 300
interactive_timeout       = 300
max_allowed_packet        = 128M

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : CACHE SETTING
thread_stack              = 192K
thread_cache_size         = 8
sort_buffer_size          = 4M
bulk_insert_buffer_size   = 64M
tmp_table_size            = 256M
max_heap_table_size       = 256M
table_cache               = 64
table_open_cache          = 400
query_cache_limit         = 128K    ## default: 128K
query_cache_size          = 64      ## default: 64M
query_cache_type          = DEMAND  ## for more write intensive setups, set to DEMAND or OFF
read_buffer_size          = 2M
read_rnd_buffer_size      = 1M
key_buffer_size           = 128M

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Logging
general_log               = 0
log_warnings              = 2
slow_query_log            = 0
log_slow_query_time       = 10
log_slow_verbosity        = query_plan,explain
#log-queries-not-using-indexes
#log_slow_admin_statements
#log_slow_min_examined_row_limit = 1000
log_bin_trust_function_creators = 1
#sync_binlog              = 1
expire_logs_days          = 10
max_binlog_size           = 100M
#log_slave_updates
#read_only

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : InnoDB
# InnoDB is enabled by default with a 10MB datafile in /var/lib/mysql/.
# Read the manual for more InnoDB related options. There are many!
# Most important is to give InnoDB 80 % of the system RAM for buffer use:
# https://mariadb.com/kb/en/innodb-system-variables/#innodb_buffer_pool_size

default_storage_engine    = InnoDB
#innodb_log_file_size     = 50M     ## you can't just change log file size, requires special procedure
innodb_buffer_pool_size   = ${ibbuffer}M
innodb_log_buffer_size    = 8M
innodb_file_per_table     = 1
innodb_open_files         = 400
innodb_io_capacity        = 400
innodb_flush_method       = O_DIRECT
innodb_doublewrite        = 1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : MyISAM
myisam_recover_options    = BACKUP
myisam_sort_buffer_size   = 512M
open-files-limit          = 4000
concurrent_insert         = 2
#auto_increment_increment = 2
#auto_increment_offset    = 1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ : Security Features
# [Docs] https://mariadb.com/kb/en/securing-connections-for-client-and-server/
#ssl-ca                   = /etc/mysql/cacert.pem
#ssl-cert                 = /etc/mysql/server-cert.pem
#ssl-key                  = /etc/mysql/server-key.pem
#require-secure-transport = on

# this is only for embedded server
[embedded]

# This group is only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadbd]

# This group is only read by MariaDB-11.1 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mariadb-11.1]

EOL

cat > $MARIADB_SYSTEMD_CONFIG_DIR/60-galera.cnf << EOL
# MariaDB database server configuration file.
# Configured template by eRQee (rizky@prihanto.web.id)
# -------------------------------------------------------------------------------
#
# * Galera-related settings
#
# See the examples of server wsrep.cnf files in /usr/share/mariadb
# Read more at https://mariadb.com/kb/en/galera-cluster/

[galera]
# Mandatory Settings
#wsrep_on                 = ON
#wsrep_cluster_name       = "MariaDB Galera Cluster"
#wsrep_cluster_address    = gcomm://
binlog-format             = row
#report_host              = master1
#sync_binlog              = 1   ## not fab for performance, but safer
max_binlog_size           = 100M
expire_logs_days          = 10
default_storage_engine    = InnoDB
innodb_autoinc_lock_mode  = 2

# Allow server to accept connections on all interfaces.
#bind-address=0.0.0.0

# Optional Settings
#wsrep_slave_threads      = 1
innodb_flush_log_at_trx_commit  = 0

EOL

MARIADB_SYSTEMD_CONF=/etc/systemd/system/mariadb.service.d/migrated-from-my.cnf-settings.conf
cat > $MARIADB_SYSTEMD_CONF << EOL
#empty placeholder

[Service]
User=mysql
StandardOutput=syslog
StandardError=syslog
SyslogFacility=daemon
SyslogLevel=err
SyslogIdentifier=mariadbd

EOL

# restart the services
systemctl daemon-reload
systemctl restart mariadb.service

  #mysqltuner
  mkdir -p /scripts/mysqltuner
  cd /scripts/mysqltuner
  wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl -O mysqltuner.pl
  wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O basic_passwords.txt
  wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv -O vulnerabilities.csv
  chmod +x /scripts/mysqltuner/mysqltuner.pl
  echo "" >> /etc/bash.bashrc
  echo "alias mysqltuner='/scripts/mysqltuner/mysqltuner.pl --cvefile=/scripts/mysqltuner/vulnerabilities.csv --passwordfile=/scripts/mysqltuner/basic_passwords.txt'" >> /etc/bash.bashrc
  cd /tmp
fi


##########################################
#install (and configure) nginx & php-fpm #
##########################################
if [ "$appserver_type" = '1' ] || [ "$appserver_type" = '2' ] || [ "$appserver_type" = '5' ]; then

echo "Breakpoint #4 : will install nginx, apache (on port 77), php and composer"
read -p "Press any key to continue..." any_key

  apt install -y nginx nginx-doc libnginx-mod-stream-geoip libnginx-mod-http-geoip libgeoip-dev \
                 php8.2 php8.2-cli php8.2-fpm php8.2-common php8.2-dev \
                 php8.2-bcmath php8.2-bz2 php8.2-curl php8.2-dba php8.2-enchant php8.2-gd php8.2-gnupg php8.2-imagick php8.2-imap php8.2-intl php8.2-mailparse php8.2-mbstring \
                 php8.2-mcrypt php8.2-mongodb php8.2-msgpack php8.2-mysql php8.2-odbc php8.2-opcache php8.2-pgsql php8.2-http php8.2-ps php8.2-pspell php8.2-psr php8.2-readline \
                 php8.2-redis php8.2-raphf php8.2-sqlite3 php8.2-ssh2 php8.2-stomp php8.2-uploadprogress php8.2-uuid php8.2-xml php8.2-xmlrpc php8.2-yaml php8.2-zip

##########################################
# configuring the webservers             #
##########################################

# backup original nginx configs
mkdir -p /etc/nginx/0riginal.config
mv /etc/nginx/fastcgi_params /etc/nginx/0riginal.config/
mv /etc/nginx/nginx.conf /etc/nginx/0riginal.config/

# configure fastcgi_params
cat > /etc/nginx/fastcgi_params << 'EOL'
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;

fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;
fastcgi_param  REQUEST_SCHEME     $scheme;
fastcgi_param  HTTPS              $https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  REMOTE_USER        $remote_user;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;

fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
fastcgi_param  PATH_INFO          $fastcgi_path_info;
fastcgi_param  PATH_TRANSLATED    $document_root$fastcgi_path_info;
EOL

# configure nginx.conf
cpu_core_count=$( nproc )
NGINX_CONFIG_FILE=/etc/nginx/nginx.conf

cat > $NGINX_CONFIG_FILE << EOL
##---------------------------------------------##
# Last Update Sep 30, 2023  05:23 WIB by eRQee  #
##---------------------------------------------##

user                            www-data;
worker_processes                ${cpu_core_count};

EOL

cat >> $NGINX_CONFIG_FILE << 'EOL'
pid                             /var/run/nginx.pid;
include                         /etc/nginx/modules-enabled/*.conf;
worker_rlimit_nofile            8192;

events {
  worker_connections            8000;
}

http {
  include                       /etc/nginx/mime.types;
  default_type                  application/octet-stream;
  charset                       utf-8;
  charset_types                 text/css text/plain text/vnd.wap.wml text/javascript text/markdown text/calendar text/x-component text/vcard text/cache-manifest text/vtt application/json application/manifest+json;

  log_format  main              '$status $time_local $remote_addr $body_bytes_sent "$request" "$http_referer" "$http_user_agent" "$http_x_forwarded_for"';
  log_format  gzip              '$status $time_local $remote_addr $body_bytes_sent "$request" "$http_referer" "$http_user_agent" "$http_x_forwarded_for" "$gzip_ratio"';
  log_format  scripts           '$document_root$fastcgi_script_name > $request';

  sendfile                      on;
  tcp_nopush                    on;
  tcp_nodelay                   on;
  types_hash_max_size           2048;
  server_tokens                 off;
  server_names_hash_bucket_size 512;
  server_name_in_redirect       off;

  gzip                          on;
  gzip_comp_level               6;
  gzip_vary                     on;
  gzip_proxied                  any;
  gzip_buffers                  16 8k;
  gzip_http_version             1.1;
  gzip_types                    application/atom+xml application/geo+json application/javascript application/x-javascript application/json application/ld+json application/manifest+json application/rdf+xml application/rss+xml application/vnd.ms-fontobject application/wasm application/x-web-app-manifest+json application/xhtml+xml application/xml font/eot font/otf font/ttf image/bmp image/svg+xml text/cache-manifest text/calendar text/css text/javascript text/markdown text/plain text/xml text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
  gzip_disable                  "msie6";

  access_log                    /dev/null main;
  error_log                     /dev/null warn;

  keepalive_timeout             20s;
  send_timeout                  10;
  proxy_connect_timeout         60;
  proxy_send_timeout            60;
  proxy_read_timeout            60;
  client_header_timeout         12;
  client_body_timeout           12;
  fastcgi_read_timeout          600;
  fastcgi_buffer_size           32k;
  fastcgi_buffers               16 16k;

  client_max_body_size          100M;
  fastcgi_max_temp_file_size    0;

  map $http_upgrade $connection_upgrade {
    default   upgrade;
    ''        close;
  }

  upstream apache    { server 127.0.0.1:77; }
EOL

if [ "$appserver_type" = '5' ]; then
  echo "  upstream odoo      { server 127.0.0.1:8069; }" >> $NGINX_CONFIG_FILE
fi

cat >> $NGINX_CONFIG_FILE << 'EOL'
  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*.conf;
}
EOL

# configure systemd override for nginx.service
mkdir -p /etc/systemd/system/nginx.service.d
printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf

#################################
## eRQee's nginx custom config ##
#################################
#
# usage examples, see the default site-enabled (virtualhost) script below
#
mkdir -p /etc/nginx/snippets

### custom config 1 : security snippet
cat > /etc/nginx/snippets/security.conf << 'EOL'
## Only requests to our Host are allowed
# if ($host !~ ^($server_name)$ ) { return 444; }
## Only allow these request methods
if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE|OPTIONS)$ ) { return 444; }
## Deny certain Referers
if ( $http_referer ~* (babes|love|nudit|poker|porn|sex) )  { return 404; return 403; }
## Cache the static contents
location ~* ^.+.(jpg|jpeg|gif|png|ico|svg|woff|woff2|ttf|eot|txt|swf|mp4|ogg|flv|mp3|wav|mid|mkv|avi|3gp|webm|webp)$ { access_log off; expires max; }
EOL

### custom config 2 : SSL snippet
mkdir -p /etc/nginx/certs
wget -O /etc/nginx/certs/lets-encrypt-x3-cross-signed.pem "https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem"
openssl dhparam -out /etc/nginx/certs/dhparam.pem 2048

cat > /etc/nginx/snippets/ssl-params.conf << 'EOL'
ssl_protocols             TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_session_cache         shared:le_nginx_SSL:10m;
ssl_session_timeout       1440m;
ssl_session_tickets       off;

ssl_ciphers               "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS";
ssl_ecdh_curve            secp521r1:secp384r1;
ssl_dhparam               /etc/nginx/certs/dhparam.pem;

ssl_stapling              on;
ssl_stapling_verify       on;
resolver                  8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout          10s;
ssl_trusted_certificate   /etc/nginx/certs/lets-encrypt-x3-cross-signed.pem;

add_header                Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
add_header                X-Frame-Options SAMEORIGIN;
add_header                X-Content-Type-Options nosniff always;
add_header                X-XSS-Protection "1; mode=block" always;

EOL

### custom config 3 : reverse proxy snippet
cat > /etc/nginx/snippets/reverse-proxy.conf << 'EOL'
proxy_next_upstream       error timeout invalid_header http_500 http_502 http_503 http_504;
proxy_redirect            off;
proxy_buffering           off;
proxy_set_header          X-Forwarded-Proto       $scheme;
proxy_set_header          Host                    $http_host;
proxy_set_header          X-Forwarded-Host        $http_host;
proxy_set_header          X-Real-IP               $remote_addr;
proxy_set_header          X-Forwarded-For         $proxy_add_x_forwarded_for;
proxy_set_header          X-Frame-Options         SAMEORIGIN;
proxy_connect_timeout     60;
proxy_send_timeout        60;
proxy_read_timeout        60;
EOL

### custom config 3 : reverse proxy to websocket snippet
cat > /etc/nginx/snippets/websocket-reverse-proxy.conf << 'EOL'
proxy_next_upstream       error timeout invalid_header http_500 http_502 http_503 http_504;
proxy_http_version        1.1;
proxy_set_header          Upgrade $http_upgrade;
proxy_set_header          Connection $connection_upgrade;
proxy_redirect            off;
proxy_buffering           off;
proxy_set_header          X-Forwarded-Proto       $scheme;
proxy_set_header          Host                    $http_host;
proxy_set_header          X-Forwarded-Host        $http_host;
proxy_set_header          X-Real-IP               $remote_addr;
proxy_set_header          X-Forwarded-For         $proxy_add_x_forwarded_for;
proxy_set_header          X-Frame-Options         SAMEORIGIN;
proxy_connect_timeout     60;
proxy_send_timeout        60;
proxy_read_timeout        60;
EOL

###########################################################################
## eRQee's examples of virtualhost site registration on nginx            ##
###########################################################################
#
# the example scripts will available in /etc/nginx/sites-availables
# (yeah, this config kinda mimic the apache2 configuration perspectives)
#

mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled
echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/info.php

cat > /etc/nginx/sites-available/000default.conf << 'EOL'
server {
  listen                     80;
  #listen                    [::]:80;
  server_name                nginx.example.domain;

  access_log                 /dev/null gzip;
  error_log                  /dev/null notice;

  root                       /usr/share/nginx/html;
  index                      index.php index.html info.php ;

  error_page                 404              /404.html;
  error_page                 500 502 503 504  /50x.html;
  location =                 /50x.html { root  /usr/share/nginx/html; }

  # location / { try_files $uri $uri/ /index.php$is_args$args; }  ## enable this line if you use PHP framework

  location ~ [^/]\.php(/|$) {
    if (!-f $document_root$fastcgi_script_name) { return 404; }
    fastcgi_split_path_info  ^(.+?\.php)(/.*)$;
    ## [alternative] ##      fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass             unix:/var/run/php8.2-fpm.sock;
    fastcgi_index            index.php;
    include                  /etc/nginx/fastcgi_params;
  }

  location ~ /\.ht { deny all; }

  location ~ /.well-known/acme-challenge {
    allow all;
  }

  include                    /etc/nginx/snippets/security.conf;
  client_max_body_size       20M;
}
EOL

rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/000default.conf /etc/nginx/sites-enabled/000default.conf

cat > /etc/nginx/sites-available/000default-ssl.conf << 'EOL'
server {
  listen                     80;
  #listen                    [::]:80;
  server_name                nginx.example.domain;
  return 301                 https://$server_name$request_uri;
}

server {
  listen                     443 ssl;
  #listen                    [::]:443 ssl ipv6only=on;
  http2                      on;
  server_name                nginx.example.domain;

  access_log                 /dev/null gzip;
  error_log                  /dev/null notice;

  ssl_certificate            /etc/letsencrypt/live/nginx.example.domain/fullchain.pem;
  ssl_certificate_key        /etc/letsencrypt/live/nginx.example.domain/privkey.pem;
  include                    /etc/nginx/snippets/ssl-params.conf;

  root                       /var/www/nginx.example.domain/;
  index                      index.php index.html info.php;

  error_page                 404              /404.html;
  error_page                 500 502 503 504  /50x.html;
  location =                 /50x.html { root  /usr/share/nginx/html/; }

  # location / { try_files $uri $uri/ /index.php$is_args$args; }  ## enable this line if you use PHP framework

  location ~ [^/]\.php(/|$) {
    if (!-f $document_root$fastcgi_script_name) { return 404; }
    fastcgi_split_path_info  ^(.+?\.php)(/.*)$;
    ## [alternative] ##      fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass             unix:/var/run/php8.2-fpm.sock;
    fastcgi_index            index.php;
    include                  /etc/nginx/fastcgi_params;
  }

  location ~ /\.ht { deny all; }
  location /.well-known/acme-challenge/ { root /usr/share/nginx/html; log_not_found off; }

  include                /etc/nginx/snippets/security.conf;
  client_max_body_size   20M;
}
EOL


cat > /etc/nginx/sites-available/000default-ssl-reverse-proxy.conf << 'EOL'
server {
  listen                     80;
  #listen                    [::]:80;
  server_name                nginx.example.domain;
  return 301                 https://$server_name$request_uri;
}

server {
  listen                     443 ssl;
  #listen                    [::]:443 ssl ipv6only=on;
  http2                      on;
  server_name                nginx.example.domain;

  access_log                 /dev/null gzip;
  error_log                  /dev/null notice;

  ssl_certificate            /etc/letsencrypt/live/nginx.example.domain/fullchain.pem;
  ssl_certificate_key        /etc/letsencrypt/live/nginx.example.domain/privkey.pem;
  include                    /etc/nginx/snippets/ssl-params.conf;

  root                       /var/www/nginx.example.domain/;

  location / {
    proxy_pass               http://apache;
    error_page               502 = /502.html;
    include                  /etc/nginx/snippets/reverse-proxy.conf;
    send_timeout             60;
    client_max_body_size     100M;
    client_body_buffer_size  100M;
  }
}
EOL

cat > /etc/nginx/sites-available/000default-ssl-websocket-reverse-proxy.conf << 'EOL'
server {
  listen                     80;
  #listen                    [::]:80;
  server_name                nginx.example.domain;
  return 301                 https://$server_name$request_uri;
}

upstream mywebsocketapp {
  ip_hash;
  server 127.0.0.1:8888;
  server 127.0.0.1:8989;
}

server {
  listen                     443 ssl;
  #listen                    [::]:443 ssl ipv6only=on;
  http2                      on;
  server_name                nginx.example.domain;

  access_log                 /dev/null gzip;
  error_log                  /dev/null notice;

  ssl_certificate            /etc/letsencrypt/live/nginx.example.domain/fullchain.pem;
  ssl_certificate_key        /etc/letsencrypt/live/nginx.example.domain/privkey.pem;
  include                    /etc/nginx/snippets/ssl-params.conf;

  root                       /var/www/nginx.example.domain/;

  location / {
    proxy_pass               http://mywebsocketapp;
    error_page               502 = /502.html;
    include                  /etc/nginx/snippets/websocket-reverse-proxy.conf;
    send_timeout             60;
    client_max_body_size     100M;
    client_body_buffer_size  100M;
  }
}
EOL

  ############################
  ## configuring php8.2-fpm ##
  ############################

  mkdir -p /var/lib/php/8.2/sessions
  chmod -R 777 /var/lib/php/8.2/sessions

  # backup existing configuration
  mkdir -p /etc/php/8.2/0riginal.config
  cp /etc/php/8.2/fpm/php.ini /etc/php/8.2/0riginal.config/php-fpm.ini
  cp /etc/php/8.2/cli/php.ini /etc/php/8.2/0riginal.config/php-cli.ini
  cp /etc/php/8.2/fpm/pool.d/www.conf /etc/php/8.2/0riginal.config/fpm-pool.d-www.conf

  PHP_INI_FILE=/etc/php/8.2/fpm/php.ini
  sed -i '/post_max_size/c\post_max_size = 100M' $PHP_INI_FILE
  sed -i '/;cgi.fix_pathinfo/c\cgi.fix_pathinfo=1' $PHP_INI_FILE
  sed -i '/;upload_tmp_dir/c\upload_tmp_dir=/tmp' $PHP_INI_FILE
  sed -i '/upload_max_filesize/c\upload_max_filesize=64M' $PHP_INI_FILE
  sed -i '/;date.timezone/c\date.timezone=Asia/Jakarta' $PHP_INI_FILE
  sed -i '/;date.default_latitude/c\date.default_latitude = -6.211544' $PHP_INI_FILE
  sed -i '/;date.default_longitude/c\date.default_longitude = 106.84517200000005' $PHP_INI_FILE
  sed -i '/;session.save_path/c\session.save_path = "/var/lib/php/8.2/sessions"' $PHP_INI_FILE
  sed -i '/;opcache.enable=1/c\opcache.enable=1' $PHP_INI_FILE
  sed -i '/;opcache.enable_cli=0/c\opcache.enable_cli=1' $PHP_INI_FILE
  sed -i '/;sendmail_path/c\sendmail_path = "/usr/bin/msmtp -C /etc/msmtprc -a -t"' $PHP_INI_FILE

  PHP_INI_FILE=/etc/php/8.2/cli/php.ini
  sed -i '/post_max_size/c\post_max_size = 100M' $PHP_INI_FILE
  sed -i '/;cgi.fix_pathinfo/c\cgi.fix_pathinfo=1' $PHP_INI_FILE
  sed -i '/;upload_tmp_dir/c\upload_tmp_dir=/tmp' $PHP_INI_FILE
  sed -i '/upload_max_filesize/c\upload_max_filesize=64M' $PHP_INI_FILE
  sed -i '/;date.timezone/c\date.timezone=Asia/Jakarta' $PHP_INI_FILE
  sed -i '/;date.default_latitude/c\date.default_latitude = -6.211544' $PHP_INI_FILE
  sed -i '/;date.default_longitude/c\date.default_longitude = 106.84517200000005' $PHP_INI_FILE
  sed -i '/;session.save_path/c\session.save_path = "/var/lib/php/8.2/sessions"' $PHP_INI_FILE
  sed -i '/;opcache.enable=1/c\opcache.enable=1' $PHP_INI_FILE
  sed -i '/;opcache.enable_cli=0/c\opcache.enable_cli=1' $PHP_INI_FILE
  sed -i '/;sendmail_path/c\sendmail_path = "/usr/bin/msmtp -C /etc/msmtprc -a -t"' $PHP_INI_FILE

  PHP_WWW_CONF_FILE=/etc/php/8.2/fpm/pool.d/www.conf
  sed -i '/listen = \/run\/php\/php8.2-fpm.sock/c\listen = \/var\/run\/php8.2-fpm.sock' $PHP_WWW_CONF_FILE
  sed -i '/;listen.mode = 0660/c\listen.mode = 0660' $PHP_WWW_CONF_FILE
  sed -i '/pm.max_children/c\pm.max_children = 10' $PHP_WWW_CONF_FILE
  sed -i '/pm.min_spare_servers/c\pm.min_spare_servers = 2' $PHP_WWW_CONF_FILE
  sed -i '/pm.max_spare_servers/c\pm.max_spare_servers = 8' $PHP_WWW_CONF_FILE

  # create the webroot workspaces
  mkdir -p /var/www/

  #################################
  ## Apache2 Redundant Webserver ##
  #################################
  # create secondary webserver instance (Apache) that runs in port 77 (HTTP) and 7447 (HTTP/SSL)
  #

  systemctl stop nginx.service
  apt install -y apache2
  a2enmod actions alias deflate expires headers http2 negotiation proxy proxy_fcgi proxy_http2 reflector remoteip rewrite setenvif substitute vhost_alias

  this_server_name="$(hostname).apache"
  sed -i "/#ServerRoot/a ServerName $this_server_name" /etc/apache2/apache2.conf
  sed -i '/Listen 80/c\Listen 0.0.0.0:77' /etc/apache2/ports.conf
  sed -i '/Listen 443/c\Listen 0.0.0.0:7447' /etc/apache2/ports.conf

cat > /etc/apache2/sites-available/000-default.conf << 'EOL'
<VirtualHost 127.0.0.1:77>
    ServerName apache.example.domain
    DocumentRoot /usr/share/apache2/default-site

    <Directory /usr/share/apache2/default-site>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/var/run/php8.2-fpm.sock|fcgi://localhost"
    </FilesMatch>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

  echo '<?php phpinfo(); ?>' > /usr/share/apache2/default-site/info.php

  rm -R /var/www/html
  chown -R www-data:www-data /var/www/

  # restart all of the webserver's daemon
  systemctl daemon-reload
  systemctl enable nginx
  systemctl restart apache2.service
  systemctl restart nginx.service
  systemctl restart php8.2-fpm

# normalize the /etc/hosts values
cfg_hostname=$(hostname)
cat > /etc/hosts << EOL
127.0.0.1       localhost
127.0.0.1       ${cfg_hostname}   ${cfg_hostname}.apache

# VirtualHost addresses.
# Normally you do not need to register all of your project addresses here.
# You must configure this on your client /etc/hosts or via your DNS Resolver

127.0.0.1       nginx.example.domain   apache.example.domain


# The following lines are desirable for IPv6 capable hosts
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

EOL

  ####################
  # install devtools #
  ####################

  cd /tmp
  curl -sS https://getcomposer.org/installer | php
  chmod +x composer.phar
  mv composer.phar /usr/local/bin/composer

  wget https://get.symfony.com/cli/installer -O - | bash
  mv ~/.symfony5/bin/symfony /usr/local/bin/symfony

  ################
  #install redis #
  ################
  apt install -y redis-server
  usermod -g www-data redis
  mkdir -p /var/run/redis
  chown -R redis:www-data /var/run/redis
  sed -i '/\<supervised no\>/c\supervised systemd' /etc/redis/redis.conf
  # set random password
  redis_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  sed -i "/# requirepass foobared/c\requirepass $redis_password" /etc/redis/redis.conf
  # make redis-server just listen to unix socket rather dan listen to global network via TCP
  sed -i '/\<# bind 127.0.0.1 ::1\>/c\bind 127.0.0.1 ::1' /etc/redis/redis.conf
  sed -i '/\<# unixsocket /var/run/redis/redis-server.sock\>/c\unixsocket /var/run/redis/redis.sock' /etc/redis/redis.conf
  sed -i '/\<# unixsocketperm 700\>/c\unixsocketperm 775' /etc/redis/redis.conf
  # other optimization
  sed -i '/\<stop-writes-on-bgsave-error yes\>/c\stop-writes-on-bgsave-error no' /etc/redis/redis.conf
  echo "maxmemory 50M" >> /etc/redis/redis.conf
  echo "maxmemory-policy allkeys-lru" >> /etc/redis/redis.conf

  systemctl restart redis-server

fi

cd /tmp

#############################################
# install (and configure) postgresql        #
#############################################
if [ "$appserver_type" = '4' ] || [ "$appserver_type" = '5' ]; then
  
echo "Breakpoint #5 : will install postgresql database"
read -p "Press any key to continue..." any_key

  apt install -y postgresql-15 postgresql-client-15 postgresql-server-dev-15 libpq-dev

  if [ "$appserver_type" = '4' ]; then
    adduser --system --quiet --shell=/bin/bash --home=/home/enterprise --gecos 'enterprise' --group enterprise
    echo "Create PostgreSQL EnterpriseDB User (enterprise)"
    sudo -u postgres -H createuser --createdb --username postgres --no-createrole --no-superuser enterprise
    service postgresql start
    sudo -u postgres -H psql -c"ALTER user enterprise WITH PASSWORD '$db_root_password'"
    service postgresql restart
  fi

fi

#############################################
# install (and configure) odoo 15           #
#############################################

cd /tmp
if [ "$appserver_type" = '5' ]; then

echo "Breakpoint #6 : will install odoo"
read -p "Press any key to continue..." any_key

  echo "Installing necessary python libraries"
  apt install -y python3-pip python3-setuptools python3-dev python3-openid python3-yaml python3-ldap
  pip3 install babel psycopg2 werkzeug simplejson pillow lxml cups \
               dateutils decorator docutils feedparser geoip gevent \
               jinja2 mako mock passlib psutil pydot \
               pyparsing reportlab requests tz unicodecsv unittest2 \
               vatnumber vobject

  echo "--------------------------------"
  echo " INSTALLING odoo v15 ..........."
  echo "--------------------------------"

  cd /tmp
  adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --gecos 'odoo' --group odoo
  mkdir /etc/odoo && mkdir /var/log/odoo/

  echo "Create PostgreSQL User"
  sudo -u postgres -H createuser --createdb --username postgres --no-createrole --no-superuser odoo
  service postgresql start
  sudo -u postgres -H psql -c"ALTER user odoo WITH PASSWORD '$db_root_password'"
  service postgresql restart

  echo "Clone the Odoo 15 latest sources"
  cd /opt/odoo
  sudo -u odoo -H git clone https://github.com/odoo/odoo --depth 1 --branch 16.0 --single-branch .
  mkdir -p /opt/odoo/addons
  chown -R odoo:odoo /opt/odoo
  chown -R odoo:odoo /var/log/odoo/

  echo "Write odoo global configuration to /etc/odoo-server.conf"

cat > /etc/odoo-server.conf << EOL
[options]
; This is the password that allows database operations:
; admin_passwd = admin
db_host = False
db_port = False
db_user = odoo
db_password = ${db_root_password}
addons_path = /opt/odoo/addons
logfile = /var/log/odoo/odoo-server.log

EOL

  chown odoo: /etc/odoo-server.conf
  chmod 640 /etc/odoo-server.conf

  echo "install another odoo dependencies..."
  cd /opt/odoo
  npm install -g less less-plugin-clean-css rtlcss generator-feathers graceful-fs@^4.0.0 yo minimatch@^3.0.2 -y
  pip3 install -r requirements.txt

  echo "Write odoo startup script to /etc/init.d/odoo-server"

cat > /etc/init.d/odoo-server << 'EOL'

#!/bin/sh
### BEGIN INIT INFO
# Provides:             odoo-server
# Required-Start:       $remote_fs $syslog
# Required-Stop:        $remote_fs $syslog
# Should-Start:         $network
# Should-Stop:          $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    Complete Business Application software
# Description:          Odoo is a complete suite of business tools.
### END INIT INFO
PATH=/bin:/sbin:/usr/bin:/usr/local/bin
DAEMON=/opt/odoo/odoo-bin
NAME=odoo-server
DESC=odoo-server
# Specify the user name (Default: odoo).
USER=odoo
# Specify an alternate config file (Default: /etc/odoo-server.conf).
CONFIGFILE="/etc/odoo-server.conf"
# pidfile
PIDFILE=/var/run/$NAME.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c $CONFIGFILE"
[ -x $DAEMON ] || exit 0
[ -f $CONFIGFILE ] || exit 0
checkpid() {
    [ -f $PIDFILE ] || return 1
    pid=`cat $PIDFILE`
    [ -d /proc/$pid ] && return 0
    return 1
}
case "${1}" in
        start)
                echo -n "Starting ${DESC}: "
                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                        --chuid ${USER} --background --make-pidfile \
                        --exec ${DAEMON} -- ${DAEMON_OPTS}
                echo "${NAME}."
                ;;
        stop)
                echo -n "Stopping ${DESC}: "
                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                        --oknodo
                echo "${NAME}."
                ;;
        restart|force-reload)
                echo -n "Restarting ${DESC}: "
                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                        --oknodo

                sleep 1
                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                        --chuid ${USER} --background --make-pidfile \
                        --exec ${DAEMON} -- ${DAEMON_OPTS}
                echo "${NAME}."
                ;;
        *)
                N=/etc/init.d/${NAME}
                echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2
                exit 1
                ;;
esac
exit 0

EOL

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
echo "***************************************************************" > $install_summarize
echo "   DEBIAN ${lsb_deb_version} PERFECT APPLICATION SERVER INSTALLER   " >> $install_summarize
echo "    -- proudly present by eRQee (rizky@prihanto.web.id)  --    " >> $install_summarize
echo "                          *   *   *                            " >> $install_summarize
echo "                      INSTALL SUMMARIZE                        " >> $install_summarize
echo "***************************************************************" >> $install_summarize
echo "" >> $install_summarize
echo "Done installing at $timestamp_flag" >> $install_summarize
echo "Using repo http://$repo_src" >> $install_summarize
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
if [ ! -z "$git_user_email" ]; then
  git_ver=$(git --version)
  echo "[Git Information]"  >> $install_summarize
  echo "$git_ver" >> $install_summarize
  git config --list >> $install_summarize 2>&1
fi
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
echo "please copy this into yout Git Repository account \"$git_user_name\" (a.k.a. $git_user_email)" >> $install_summarize
echo "" >> $install_summarize
cat /root/.ssh/id_rsa.pub >> $install_summarize 2>&1
echo "" >> $install_summarize
echo "" >> $install_summarize
echo "***********************************************************" >> $install_summarize
echo "                           ENJOY                           " >> $install_summarize
echo "***********************************************************" >> $install_summarize
cat $install_summarize

######################################
# Send the installation log to email #
######################################

if [ ! -z "$zoho_mail_account" ]; then
  public_ip=$( curl https://ifconfig.me/ip  )
  timestamp_flag=` date +%F-%H-%M-%S`
  mail_subject="Server $public_ip installed with Debian $lsb_deb_version!"
  echo "Well done!" > /tmp/mail-body.txt
  echo "You've finished the Debian ${lsb_deb_version} Perfect Server installation on $public_ip at $timestamp_flag." >> /tmp/mail-body.txt
  echo "" >> /tmp/mail-body.txt
  echo "Please review the attached install summarize report below, and keep for future references." >> /tmp/mail-body.txt
  echo "" >> /tmp/mail-body.txt
  echo "--" >> /tmp/mail-body.txt
  echo "Your Private Auto DevOps" >> /tmp/mail-body.txt
  cp $install_summarize /tmp/install-log-$timestamp_flag.txt
  mutt -a "/tmp/install-log-$timestamp_flag.txt" -s "$mail_subject" -- "$git_user_email" < /tmp/mail-body.txt
fi
rm $install_summarize
exit 0
