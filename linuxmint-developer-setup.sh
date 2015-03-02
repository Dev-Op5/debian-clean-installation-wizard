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

if [ $TVer = "17" ] || [ $TVer = "17.1" ]; then
  echo "You are running LinuxMint 17 or 17.1. The process will be continued..."
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


mv $repo /etc/apt/old.sources.list
touch $repo

rm /etc/apt/sources.list.d/official-package-repositories.list
rm /etc/apt/sources.list.d/official-source-repositories.list

echo "deb http://$repo_src/linuxmint $lmversion main upstream import" >> $repo
echo "deb-src http://$repo_src/linuxmint $lmversion main upstream import" >> $repo
echo "deb http://extra.linuxmint.com $lmversion main" >> $repo
echo "deb-src http://extra.linuxmint.com $lmversion main" >> $repo
echo "deb http://$repo_src/ubuntu trusty main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_src/ubuntu trusty main restricted universe multiverse" >> $repo
echo "deb http://$repo_src/ubuntu trusty-updates main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_src/ubuntu trusty-updates main restricted universe multiverse" >> $repo
echo "deb http://$repo_src/ubuntu/ trusty-security main restricted universe multiverse" >> $repo
echo "deb-src http://$repo_src/ubuntu/ trusty-security main restricted universe multiverse" >> $repo
echo "deb http://archive.canonical.com/ubuntu/ trusty partner" >> $repo
echo "deb-src http://archive.canonical.com/ubuntu/ trusty partner" >> $repo
echo "deb http://nginx.org/packages/mainline/debian/ wheezy nginx" >> $repo
echo "deb-src http://nginx.org/packages/mainline/debian/ wheezy nginx" >> $repo
echo "deb http://mariadb.biz.net.id//repo/10.1/debian wheezy main" >> $repo
echo "deb-src http://mariadb.biz.net.id//repo/10.1/debian wheezy main" >> $repo
echo "deb http://$repo_src/dotdeb wheezy all" >> $repo
echo "deb-src http://$repo_src/dotdeb wheezy all" >> $repo
echo "deb http://$repo_src/dotdeb wheezy-php55 all" >> $repo
echo "deb-src http://$repo_src/dotdeb wheezy-php55 all" >> $repo
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


############################
#update the repository list#
############################
echo "Updating & upgrading the repositories..."
apt-get update -y
dpkg-reconfigure locales
apt-get autoremove gedit gedit-common
aptitude full-upgrade -y
apt-get install -y ia32-libs bash-completion consolekit firmware-linux-free gnupg-curl members libuser openssh-server openssh-client

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
                   libreadline-dev libxslt-dev

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
curl -sL https://deb.nodesource.com/setup | bash -
apt-get install -y nodejs

###################
#install phantomjs#
###################
echo "Install PhantomJS"
cd /tmp
wget http://src.mokapedia.net/linux-x64/phantomjs-1.9.7-linux-x86_64.tar.bz2
tar jxf phantomjs-1.9.7-linux-x86_64.tar.bz2
cp phantomjs-1.9.7-linux-x86_64/bin/phantomjs /usr/bin

#################################
#install (and configure) mariadb#
#################################

#export DEBIAN_FRONTEND=noninteractive
echo "Install MariaDB 10.1.x with default root password '123123password'"
#debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password password 123123password'
#debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password_again password 123123password'
apt-get install -y mariadb-server-10.1 mariadb-client-10.1 libmariadbclient-dev mariadb-connect-engine-10.1 mariadb-oqgraph-engine-10.1 mariadb-test-10.1

echo "Reconfigure the MariaDB my.cnf"
  cd /tmp
  wget http://src.mokapedia.net/others/config/my.cnf
  mv /etc/mysql/my.cnf /etc/mysql/my.cnf.original
  cp /tmp/my.cnf /etc/mysql/my.cnf

  # restart the services
  service mysql restart

echo "Install MySQL UDF"
  cd /tmp
  wget http://src.mokapedia.net/others/lib_mysqludf_debian.tar.gz
  tar zxvf lib_mysqludf_debian.tar.gz
  cd /tmp/lib_mysqludf_debian
  cp bin/* /usr/lib/mysql/plugin
  mysql -uroot --password=123123password mysql < udf_initialize.sql

  # restart the services again
  service mysql restart

echo "Install Nginx 1.7x & PHP5-FPM 5.6.x"

apt-get install -y   nginx php5 php5-fpm php5-cgi php5-cli php5-common php5-curl php5-dbg php5-dev php5-enchant php5-gd \
                     php5-gmp php5-imap php5-ldap php5-mcrypt php5-mysqlnd php5-odbc php5-pgsql \
                     php5-pspell php5-readline php5-recode php5-sqlite php5-sybase php5-tidy php5-xmlrpc php5-xsl php-pear \
                     php5-geoip php5-mongo php5-imagick php-fpdf php5-apcu libmariadbclient-dev

echo "Configuring nginx..."
  mkdir -p /etc/nginx/sites-enabled
  mkdir -p /tmp/config/
  cd /tmp/config
  wget http://src.mokapedia.net/others/config/fastcgi_params
  mv /etc/nginx/fastcgi_params /etc/nginx/original.fastcgi_params
  cp fastcgi_params /etc/nginx/fastcgi_params

  wget http://src.mokapedia.net/others/config/nginx.conf
  mv /etc/nginx/nginx.conf /etc/nginx/nginx.original.conf
  cp nginx.conf /etc/nginx/nginx.conf

  wget http://src.mokapedia.net/others/config/security.conf
  cp security.conf /etc/nginx/security.conf

echo "Configuring PHP5-FPM..."
  mkdir -p /var/lib/php5/sessions
  mkdir -p /var/lib/php5/cookies
  chmod -R 777 /var/lib/php5/sessions
  chmod -R 777 /var/lib/php5/cookies
  cd /tmp/config

  wget http://src.mokapedia.net/others/config/php.ini
  wget http://src.mokapedia.net/others/config/www.conf

  mv /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini-original
  mv /etc/php5/cli/php.ini /etc/php5/cli/php.ini-original
  cp php.ini /etc/php5/fpm/php.ini
  cp php.ini /etc/php5/cli/php.ini
  mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf-original
  cp www.conf /etc/php5/fpm/pool.d/www.conf

echo "Configuring the website workspaces..."

  cd /tmp/config
  wget http://src.mokapedia.net/others/config/000default.conf
  cp 000default.conf /etc/nginx/sites-enabled/

  # restart the services
  service nginx restart && service php5-fpm restart

  # create the webroot workspaces
  mkdir -p /var/www
  chown -R www-data:www-data /var/www

  #########################
  # install composer.phar #
  #########################

echo "Install composer..."

  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer

  ###############################
  # install python dependencies #
  ###############################

  apt-get install -y python-dateutil python-docutils python-feedparser python-gdata python-jinja2 python-ldap python-libxslt1 python-lxml \
                     python-mako python-mock python-openid python-passlib python-psycopg2 python-psutil python-pybabel python-pychart \
                     python-pydot python-pyparsing python-pypdf python-reportlab python-simplejson python-tz python-unittest2 python-vatnumber \
                     python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi

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

  #########################
  # install SublimeText 3 #
  #########################

echo "Installing SublimeText3"
cd /tmp/
wget http://src.mokapedia.net/linux-x64/sublime-text_build-3065_amd64.deb
dpkg -i sublime-text_build-3065_amd64.deb
mv /opt/sublime_text/sublime_text /opt/sublime_text/sublime_text_original
wget http://src.mokapedia.net/linux-x64/sublime_text_crack
mv sublime_text_crack /opt/sublime_text/sublime_text
chmod +x /opt/sublime_text/sublime_text

  #################################
  # install Nice-To-Have Packages #
  #################################

echo "Installing guake, shutter, leafpad, virtualbox, and google chrome"
apt-get install -y guake shutter libgoo-canvas-perl dconf-editor arandr gparted leafpad virtualbox-4.3 google-chrome-stable chromium-browser

  ####################################
  # Config the command-line shortcut #
  ####################################

echo "alias sedot='wget --recursive --page-requisites --html-extension --convert-links --no-parent --random-wait -r -p -E -e robots=off'" >> /etc/bash.bashrc
echo "alias commit='git add --all . && git commit -m'" >> /etc/bash.bashrc
echo "alias push='git push -u origin master'" >> /etc/bash.bashrc

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