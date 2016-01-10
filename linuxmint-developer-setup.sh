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


##########################################
#Check if this is a LinuxMint 17 machine #
##########################################

CHKVer=`/usr/bin/lsb_release -rs`
TVer=`/usr/bin/lsb_release -rs`
CHKArch=`uname -m`
sleep 1
echo ""

if [ $CHKArch != "x86_64" ]; then
  echo "You are running a NON 64-bit operating system. Hare gene masih pake 32-bit, ganti lah!"
  exit 1
fi

if [ $TVer = "17" ] || [ $TVer = "17.1" ] || [ $TVer = "17.2" ] || [ $TVer = "17.3" ]; then
  echo "You are running LinuxMint 17.x The process will be continued..."
else
  echo "This script is only for Linux Mint `printf "\e[32m17 or 17.1"``echo -e "\033[0m"` (`printf "\e[32m64-bit only"``echo -e "\033[0m"`)"
  exit 1
fi

echo ""
echo "********************************************************"
echo "             LINUXMINT DEVELOPER INSTALLER              "
echo "    -- proudly present by eRQee (q@mokapedia.com) --    "
echo "********************************************************"
echo ""
echo "Which Repository do you prefer?"
echo "1. kambing.ui.ac.id"
echo "2. kartolo.sby.datautama.net.id"
echo ""
read -p "Your choice? (1/2) : " which_repo
echo ""
echo ""
echo "This script will automatically install the packages below"
echo "1. Nginx 1.7.x"
echo "2. PHP 5.6.x (CLI, CGI, and FPM)"
echo "3. MariaDB 10.1.x + UDF"
echo "4. Git 2.2 (latest)"
echo "5. NodeJS & PhantomJS"
echo "6. Composer (latest)"
echo "7. AdobeAIR 2.6 (latest supported version for linux)"
echo "8. Guake, Shutter, LeafPad, SublimeText 3, Google Chrome"
echo ""
echo ""
read -p "Enter the default database root password: " db_root_password
echo ""
read -p "Git Identifier Username   : " git_user_name
read -p "Git Identifier User Email : " git_user_email
echo ""
echo ""
read -p "Proceed to Install? (Y/N) : " lets_go

if [ "$lets_go" != 'Y' ]; then
  if [ "$lets_go" != 'y' ]; then
    exit 1
  fi
fi

echo "Updating the Software Repositories..."

repo=/etc/apt/sources.list
repo_src="kambing.ui.ac.id"

lmversion="qiana"
if [ $TVer = "17.1" ]; then
  lmversion="rebecca"
fi

if [ $TVer = "17.2" ]; then
  lmversion="rafaela"
fi

if [ $TVer = "17.3" ]; then
  lmversion="rosa"
fi

mv $repo /etc/apt/old.sources.list
touch $repo

rm /etc/apt/sources.list.d/official-package-repositories.list
rm /etc/apt/sources.list.d/official-source-repositories.list

echo "deb http://$repo_src/linuxmint $lmversion main upstream import" >> $repo
echo "deb-src http://$repo_src/linuxmint $lmversion main upstream import" >> $repo
echo "deb http://extra.linuxmint.com $lmversion main" >> $repo
echo "deb-src http://extra.linuxmint.com $lmversion main" >> $repo
echo "" >> $repo
echo "deb http://$repo_src/ubuntu trusty main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_src/ubuntu trusty main restricted universe multiverse" >> $repo
echo "deb http://$repo_src/ubuntu trusty-updates main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_src/ubuntu trusty-updates main restricted universe multiverse" >> $repo
echo "deb http://$repo_src/ubuntu/ trusty-security main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_src/ubuntu/ trusty-security main restricted universe multiverse" >> $repo
echo "deb http://archive.canonical.com/ubuntu/ trusty partner" >> $repo
echo "deb-src http://archive.canonical.com/ubuntu/ trusty partner" >> $repo

apt-get update
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 40976EAF437D05B5
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 3B4FE6ACC0B21F32
apt-get update
apt-get install -y nano

echo "" >> $repo
echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> $repo
echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> $repo
echo "deb http://mariadb.biz.net.id//repo/10.1/ubuntu trusty main" >> $repo
echo "deb-src http://mariadb.biz.net.id//repo/10.1/ubuntu trusty main" >> $repo
echo "deb http://$repo_src/dotdeb wheezy all" >> $repo
echo "deb-src http://$repo_src/dotdeb wheezy all" >> $repo
echo "deb http://$repo_src/dotdeb wheezy-php56 all" >> $repo
echo "deb-src http://$repo_src/dotdeb wheezy-php56 all" >> $repo
echo "" >> $repo
echo "deb http://dl.google.com/linux/deb/ stable main" >> $repo
echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" >> $repo

echo "Register the Public Keys..."
#dotdeb.org
wget --quiet -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -
#postgresql.org
wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
#nginx.org
wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
#mariadb.org
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
#google.com
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
#virtualbox.org
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | apt-key add -
#telegram PPA
add-apt-repository -y ppa:atareao/telegram

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
echo "Updating & upgrading the repositories..."
apt-get update -y
locale-gen en_US en_US.UTF-8 id_ID id_ID.UTF-8
dpkg-reconfigure locales
apt-get autoremove gedit gedit-common
aptitude full-upgrade -y
apt-get install -y ia32-libs bash-completion consolekit gnupg-curl members libuser openssh-server openssh-client

########################
#install the newest git#
########################

apt-get autoremove git git-core
apt-get install -y unzip libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev build-essential
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

############################
#install essential packages#
############################

apt-get install -y libxt6:i386 libnspr4-0d:i386 libgtk2.0-0:i386 libstdc++6:i386 libnss3-1d:i386 lib32nss-mdns libxml2:i386 \
                   libxslt1.1:i386 libcanberra-gtk-module:i386 gtk2-engines-murrine:i386 libgnome-keyring0:i386 libxaw7 \
                   sudo locate whois curl lynx openssl python perl libaio1 hdparm rsync traceroute imagemagick libmcrypt-dev \
                   python-software-properties pcregrep snmp-mibs-downloader tcpdump gawk checkinstall cdbs devscripts dh-make \
                   libxml-parser-perl check python-pip libbz2-dev libpcre3-dev libxml2-dev unixodbc-bin sysv-rc-conf uuid-dev \
                   libicu-dev libncurses5-dev libffi-dev debconf-utils libpng12-dev libjpeg-dev libgif-dev libevent-dev chrpath \
                   libfontconfig1-dev libxft-dev optipng g++ fakeroot ntp zip p7zip-full zlib1g-dev libyaml-dev libgdbm-dev \
                   libreadline-dev libxslt-dev libctemplate2 g++ flex bison gperf ruby perl libsqlite3-dev libfontconfig1-dev \
                   libicu-dev libfreetype6 libssl-dev libpng-dev libjpeg-dev python libX11-dev libxext-dev

###############
#configure ntp#
###############
echo "Configuring the Network Time Protocol..."
sed -i 's/debian.pool.ntp.org iburst/id.pool.ntp.org/g' /etc/ntp.conf
service ntp restart

################
#install nodejs#
################
echo "Install Node.JS"
curl -sL https://deb.nodesource.com/setup_5.x | sudo bash -
apt-get install -y nodejs

npm install -g npm@latest
npm install -g grunt-cli bower gulp less less-plugin-clean-css yo karma

###################
#install phantomjs#
###################
echo "Install PhantomJS"
cd /tmp
rm -R phantomjs
git clone git://github.com/ariya/phantomjs.git phantomjs
cd /tmp/phantomjs
git checkout 2.0
./build.sh
cp /tmp/phantomjs/bin/phantomjs /usr/bin
cd /tmp
rm -R phantomjs

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

#export DEBIAN_FRONTEND=noninteractive
echo "Install MariaDB 10.1.x with default root password supplied before"
echo "mariadb-server-10.1 mysql-server/root_password password $db_root_password" | sudo /usr/bin/debconf-set-selections
echo "mariadb-server-10.1 mysql-server/root_password_again password $db_root_password" | sudo /usr/bin/debconf-set-selections
apt-get install -y mariadb-server-10.1 mariadb-client-10.1 libmariadbclient-dev mariadb-connect-engine-10.1 mariadb-oqgraph-engine-10.1 mariadb-test-10.1

 # reconfigure my.cnf
cd /tmp
wget http://code.mokapedia.net/server/default-server-config/raw/master/my.cnf
mv /etc/mysql/my.cnf /etc/mysql/my.cnf.original
cp /tmp/my.cnf /etc/mysql/my.cnf

# restart the services
service mysql restart

# install mysql udf
cd /tmp
wget http://code.mokapedia.net/server/lib_mysqludf_debian/repository/archive.zip
unzip archive.zip
cd lib_mysqludf_debian*
sudo cp bin/* /usr/lib/mysql/plugin
mysql -uroot --password=$db_root_password < udf_initialize.sql
cd ..
rm -R lib_mysqludf_debian*
rm archive.zip

# restart the services again
service mysql restart

echo "Install Nginx 1.9x & PHP5-FPM 5.6.x"

apt-get install -y   nginx php5 php5-fpm php5-cgi php5-cli php5-common php5-curl php5-dbg php5-dev php5-enchant php5-gd \
                     php5-gmp php5-imap php5-ldap php5-mcrypt php5-mysqlnd php5-odbc php5-pgsql \
                     php5-pspell php5-readline php5-recode php5-sqlite php5-sybase php5-tidy php5-xmlrpc php5-xsl php-pear \
                     php5-geoip php5-mongo php5-imagick php-fpdf php5-apcu libmariadbclient-dev libpq-dev

echo "Configuring nginx..."
  mkdir -p /etc/nginx/sites-enabled
  mkdir -p /tmp/config/
  cd /tmp/config
  wget http://code.mokapedia.net/server/default-server-config/raw/master/fastcgi_params
  mv /etc/nginx/fastcgi_params /etc/nginx/original.fastcgi_params
  cp fastcgi_params /etc/nginx/fastcgi_params

  wget http://code.mokapedia.net/server/default-server-config/raw/master/nginx.conf
  mv /etc/nginx/nginx.conf /etc/nginx/nginx.original.conf
  cp nginx.conf /etc/nginx/nginx.conf

  wget http://code.mokapedia.net/server/default-server-config/raw/master/security.conf
  cp security.conf /etc/nginx/security.conf

echo "Configuring PHP5-FPM..."
  mkdir -p /var/lib/php5/sessions
  mkdir -p /var/lib/php5/cookies
  chmod -R 777 /var/lib/php5/sessions
  chmod -R 777 /var/lib/php5/cookies
  cd /tmp/config

  wget http://code.mokapedia.net/server/default-server-config/raw/master/php.ini
  wget http://code.mokapedia.net/server/default-server-config/raw/master/www.conf

  mv /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini-original
  mv /etc/php5/cli/php.ini /etc/php5/cli/php.ini-original
  cp php.ini /etc/php5/fpm/php.ini
  cp php.ini /etc/php5/cli/php.ini
  mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf-original
  cp www.conf /etc/php5/fpm/pool.d/www.conf

echo "Install PHP 7.0"
  add-apt-repository -y ppa:ondrej/php-7.0
  apt-get update

  apt-get install -y php7.0 php7.0-fpm php7.0-cgi php7.0-cli php7.0-common php7.0-curl php7.0-gd \
                     php7.0-imap php7.0-intl php7.0-sqlite3 php7.0-pspell php7.0-recode php7.0-snmp \
                     php7.0-json php7.0-modules-source php7.0-opcache php7.0-mcrypt php7.0-readline \
                     php7.0-bz2 php7.0-dbg php7.0-dev php7.0-mysql php7.0-pgsql libphp7.0-embed

  # configuring php7-fpm
  mkdir -p /var/lib/php7/sessions
  chmod -R 777 /var/lib/php7/sessions
  mkdir -p /var/log/php7
  chmod -R 777 /var/log/php7

  cd /tmp/config
  wget http://code.mokapedia.net/server/default-server-config/raw/master/php7/php.ini
  wget http://code.mokapedia.net/server/default-server-config/raw/master/php7/www.conf

  mv /etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini-original
  mv /etc/php/7.0/cli/php.ini /etc/php/7.0/cli/php.ini-original
  cp php.ini /etc/php/7.0/fpm/php.ini
  cp php.ini /etc/php/7.0/cli/php.ini
  mv /etc/php/7.0/fpm/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf-original
  cp www.conf /etc/php/7.0/fpm/pool.d/www.conf

echo "Configuring the website workspaces..."

  cd /tmp/config
  wget http://code.mokapedia.net/server/default-server-config/raw/master/php7/000default.conf
  cp 000default.conf /etc/nginx/sites-enabled/

  # create the webroot workspaces
  mkdir -p /var/www
  chown -R www-data:www-data /var/www

  # restart the services
  service nginx restart && service php5-fpm restart


#########################
# install composer.phar #
#########################

echo "Install composer..."

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#################################
# install Premium MaxMind GeoIP #
#################################

apt-get install -y libgeoip-dev
mv /usr/share/GeoIP/ /usr/share/GeoIP.old
mkdir -p /usr/share/GeoIP
cd /tmp
rm archive.zip
wget http://code.mokapedia.net/server/premium-geoip-database/repository/archive.zip
unzip archive.zip
cd premium-geoip-database*
cp database/*.dat /usr/share/GeoIP
cd ..
rm -R premium-geoip-database*
rm archive.zip

###############################
# install python dependencies #
###############################

apt-get install -y python-dateutil python-docutils python-feedparser python-gdata python-jinja2 python-ldap python-libxslt1 python-lxml \
                   python-mako python-mock python-openid python-passlib python-psycopg2 python-psutil python-pybabel python-pychart \
                   python-pydot python-pyparsing python-pypdf python-reportlab python-simplejson python-tz python-unittest2 python-vatnumber \
                   python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi

########################
# install Fonts        #
########################

echo "Installing Fonts ..."
# font from the repo
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get install -y ttf-mscorefonts-installer ttf-bitstream-vera ttf-anonymous-pro fonts-cantarell fonts-comfortaa \
                  fonts-crosextra-caladea fonts-crosextra-carlito

# font pilihan mokapedia
mkdir -p /tmp/fnts
cd /tmp/fnts
wget http://code.mokapedia.net/cdn/font/repository/archive.zip
unzip archive.zip
cd font*
mv ttf-mokapedia-favorites /usr/share/fonts/truetype
cd /tmp
rm -R /tmp/fnts

fc-cache -fv

########################
# install AdobeAIR     #
########################

echo "Installing AdobeAIR ..."
ln -sf /usr/lib/x86_64-linux-gnu/libgnome-keyring.so.0 /usr/lib/libgnome-keyring.so.0
ln -sf /usr/lib/x86_64-linux-gnu/libgnome-keyring.so.0.2.0 /usr/lib/libgnome-keyring.so.0.2.0

cd /tmp/
wget -O AdobeAIRInstaller.bin http://src.mokapedia.net/linux-x64/AdobeAIRInstaller.bin
chmod +x AdobeAIRInstaller.bin
./AdobeAIRInstaller.bin
rm AdobeAIRInstaller.bin
rm /usr/lib/libgnome-keyring.so.0
rm /usr/lib/libgnome-keyring.so.0.2.0
ln -s "/opt/Adobe AIR/Versions/1.0/Adobe AIR Application Installer" /usr/sbin/airinstall

#########################
# install SublimeText 3 #
#########################

echo "Installing SublimeText3"
cd /tmp/
wget http://src.mokapedia.net/linux-x64/sublime-text_build-3083_amd64.deb
dpkg -i sublime-text_build-3083_amd64.deb
cd /opt/sublime_text/
cp /opt/sublime_text/sublime_text ori_st3
printf '\x39' | dd seek=$((0xcbe3)) conv=notrunc bs=1 of=/opt/sublime_text/sublime_text

#########################
# install local apps    #
#########################

echo "Installing Local Apps"
mkdir -p /tmp/debs
cd /tmp/debs
wget http://src.mokapedia.net/linux-x64/master-pdf-editor-3.4.03_amd64.deb
wget http://src.mokapedia.net/linux-x64/teamviewer_i386.deb
wget http://src.mokapedia.net/linux-x64/mysql-workbench-community-6.3.4-1ubu1404-amd64.deb
wget http://src.mokapedia.net/linux-x64/dragondisk_1.0.5-0ubuntu_amd64.deb
wget http://src.mokapedia.net/linux-x64/dgtools_1.3.1-0ubuntu_amd64.deb

dpkg -i *.deb 
apt-get install -f -y
dpkg -i *.deb 

mkdir -p /tmp/air 
cd /tmp/air 
wget http://src.mokapedia.net/linux-x64/pomodairo-1.9.air
airinstall -silent -eulaAccepted pomodairo-1.9.air
http://src.mokapedia.net/linux-x64/Balsamiq%20Mockups/MockupsForDesktop.air
airinstall -silent -eulaAccepted MockupsForDesktop.air

####################################
# GNU Execute                      #
####################################

echo "Installing GNU Execute"
apt-get install -y ed
cd /tmp
wget http://code.mokapedia.net/server/execute/raw/master/execute
chmod +x /tmp/execute
sudo cp /tmp/execute /usr/bin

#################################
# install Nice-To-Have Packages #
#################################

echo "Installing nice-to-have packages"
apt-get install -y guake shutter libgoo-canvas-perl dconf-editor arandr gparted leafpad virtualbox-5.0 google-chrome-stable \
                   chromium-browser p11-kit-modules:i386 wine winetricks telegram geary cheese qbittorrent comic gpicview \
                   pdftk dia remmina* figlet toilet inkscape

####################################
# Config the command-line shortcut #
####################################

echo "" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc
echo "export WINEARCH=win32" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc
echo "alias sedot='wget --recursive --page-requisites --html-extension --convert-links --no-parent --random-wait -r -p -E -e robots=off'" >> /etc/bash.bashrc
echo "alias commit='git add --all . && git commit -m'" >> /etc/bash.bashrc
echo "alias push='git push -u origin master'" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc


###########################################################################
# flag the server that she's already setup perfectly (to avoid reinstall) #
###########################################################################
touch $install_summarize
timestamp_flag=` date +%F\ %H:%M:%S`

echo "********************************************************" > $install_summarize
echo "             LINUXMINT DEVELOPER INSTALLER              " >> $install_summarize
echo "    -- proudly present by eRQee (q@mokapedia.com) --    " >> $install_summarize
echo "********************************************************" >> $install_summarize
echo "" >> $install_summarize
echo "Done installing at $timestamp_flag" >> $install_summarize
echo "Using repo http://$repo_src" >> $install_summarize
echo "" >> $install_summarize

nginx_ver=$(nginx -v)
php_ver=$(php -v | grep "(cli)")
mysql_ver=$(mysql --version)
git_ver=$(git --version)
node_ver=$(node -v)
npm_ver=$(npm -v)
phantomjs_ver=$(phantomjs -v)

echo "[Web Server Information]"  >> $install_summarize
echo "$nginx_ver" >> $install_summarize
echo "$php_ver" >> $install_summarize
echo "" >> $install_summarize
echo "[MariaDB Information]" >> $install_summarize
echo "$mysql_ver" >> $install_summarize
echo "MariaDB root Password : 123123password" >> $install_summarize
echo "" >> $install_summarize
echo "[Git Information]"  >> $install_summarize
echo "$git_ver" >> $install_summarize
echo "" >> $install_summarize
echo "" >> $install_summarize
echo "******************************************************" >> $install_summarize
echo "                     HAPPY CODING !                   " >> $install_summarize
echo "******************************************************" >> $install_summarize

cat $install_summarize
/bin/bash
exit 0