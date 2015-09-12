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

if [ $TVer = "17" ] || [ $TVer = "17.1" ]  || [ $TVer = "17.2" ]  || [ $TVer = "17.3" ]; then
  echo "You are running LinuxMint 17.x The process will be continued..."
else
  echo "This script is only for Linux Mint `printf "\e[32m17.x"``echo -e "\033[0m"` (`printf "\e[32m64-bit only"``echo -e "\033[0m"`)"
  exit 1
fi

echo ""
echo "********************************************************"
echo "             LINUXMINT DEVELOPER INSTALLER              "
echo "    -- proudly present by eRQee (q@mokapedia.com) --    "
echo "********************************************************"
echo ""
echo ""
echo "This script will automatically install the packages below"
echo "1. LibreOffice 5.x"
echo "2. Google Chrome, Telegram & Teamviewer"
echo "3. Master PDF Editor, PDFTK"
echo "4. Shutter, gPicView, Leafpad"
echo "5. Oracle Java 8 Installer, ia32-libs"
echo "6. Standard Fonts"
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
#if [ $TVer = "17.3" ]; then
#  lmversion="rita"
#fi

mv $repo /etc/apt/old.sources.list
touch $repo

rm /etc/apt/sources.list.d/official-package-repositories.list
rm /etc/apt/sources.list.d/official-source-repositories.list

echo "deb http://repo.udkw.ac.id/linuxmint $lmversion main upstream import" >> $repo
echo "deb-src http://repo.udkw.ac.id/linuxmint $lmversion main upstream import" >> $repo
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
#linuxmint PPA
add-apt-repository -y ppa:libreoffice/libreoffice-5-0

############################
#update the repository list#
############################
echo "Updating & upgrading the repositories..."
apt-get update -y
dpkg-reconfigure locales
apt-get autoremove --purge -y gedit gedit-common eog gthumb gthumb-data hexchat brasero gnome-screenshot transmission-gtk totem*
aptitude full-upgrade -y
apt-get install -y ia32-libs bash-completion consolekit gnupg-curl members libuser openssh-server libreoffice-style-breeze

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

###############################
# install python dependencies #
###############################

apt-get install -y python-dateutil python-docutils python-feedparser python-gdata python-jinja2 python-ldap python-libxslt1 python-lxml \
                   python-mako python-mock python-openid python-passlib python-psycopg2 python-psutil python-pybabel python-pychart \
                   python-pydot python-pyparsing python-pypdf python-reportlab python-simplejson python-tz python-unittest2 python-vatnumber \
                   python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi

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
# install nice-to-have packages #
#################################

apt-get install -y guake shutter libgoo-canvas-perl dconf-editor arandr gparted leafpad google-chrome-stable chromium-browser pdftk telegram gpicview 

# font from the repo
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get install -y ttf-mscorefonts-installer ttf-bitstream-vera ttf-anonymous-pro fonts-cantarell fonts-comfortaa \
                  fonts-crosextra-caladea fonts-crosextra-carlito 

# font pilihan mokapedia
mkdir -p /tmp/fnts
cd /tmp/fnts
wget http://src.mokapedia.net/linux-x64/ttf-mokapedia-favorites.tar.gz 
tar zxvf ttf-mokapedia-favorites.tar.gz 
mv ttf-mokapedia-favorites /usr/share/fonts/truetype 

fc-cache -fv  

####################################
# instal apps di src.mokapedia.net #
####################################
# a) sublime-text-3                #
# b) master pdf editor             #
# c) teamviewer                    #
# d) epson 310 driver              #
####################################

gdebi -i sublime-text_build-3083_amd64.deb
cd /opt/sublime_text/
cp /opt/sublime_text/sublime_text ori_st3
printf '\x39' | dd seek=$((0xcbe3)) conv=notrunc bs=1 of=/opt/sublime_text/sublime_text

mkdir -p /tmp/debs
cd /tmp/debs
wget http://src.mokapedia.net/linux-x64/master-pdf-editor-3.4.03_amd64.deb 
wget http://src.mokapedia.net/linux-x64/teamviewer_i386.deb 
wget http://src.mokapedia.net/linux-x64/epson-inkjet-printer-201310w_1.0.0-1lsb3.2_amd64.deb

dpkg -i *.deb 

apt-get install -f -y 

dpkg -i *.deb 


####################################
# Config the command-line shortcut #
####################################

echo "" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc
echo "EXPORT WINEARCH=win32" >> /etc/bash.bashrc
echo "alias sedot='wget --recursive --page-requisites --html-extension --convert-links --no-parent --random-wait -r -p -E -e robots=off'" >> /etc/bash.bashrc

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
echo "******************************************************" >> $install_summarize
echo "                     HAPPY WORKING !                   " >> $install_summarize
echo "******************************************************" >> $install_summarize

cat $install_summarize
/bin/bash
exit 0

