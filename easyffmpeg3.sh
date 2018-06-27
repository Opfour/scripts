#!/bin/bash

# Architecture
arch=`uname -m`

# Server IP
if [ -e /dev/vzfs ]; then
	IP=`ifconfig venet0:0 | grep "inet addr" |cut -d ":" -f 2 | cut -d " " -f 1`
else
	IP=`ifconfig eth0 | grep "inet addr" |cut -d ":" -f 2 | cut -d " " -f 1`
fi

cat << EOF > /etc/yum.repos.d/dag.repo
[dag]
name=Dag RPM Repository for Red Hat Enterprise Linux
baseurl=http://apt.sw.be/redhat/el\$releasever/en/\$basearch/dag
gpgcheck=1
enabled=1
EOF

echo /usr/local/lib >> /etc/ld.so.conf && ldconfig

if [ "$arch" = "i686" ]; then
	wget -P /tmp http://dag.wieers.com/rpm/packages/rpmforge-release/rpmforge-release-0.3.6-1.el4.rf.i386.rpm
	rpm -Uvh /tmp/rpmforge-release-0.3.6-1.el4.rf.i386.rpm
else
	wget -P /tmp http://dag.wieers.com/rpm/packages/rpmforge-release/rpmforge-release-0.3.6-1.el4.rf.x86_64.rpm
	rpm -Uvh /tmp/rpmforge-release-0.3.6-1.el4.rf.x86_64.rpm
fi

# Enable perl updates or this will error out 
sed -i -e "s/perl\*\ //" /etc/yum.conf
yum -y update
yum -y install ffmpeg ffmpeg-devel

# Build PHP extension
cd /usr/local/src
wget -c http://mw.liquidweb.com/rpms/centos4/ffmpeg_stuff/ffmpeg-php-0.5.2.1.tbz2
tar xjf ffmpeg-php-0.5.2.1.tbz2
cd ffmpeg-php-0.5.2.1
phpize && ./configure && make && make install

echo -e "\nextension = ffmpeg.so\n" >> /usr/local/lib/php.ini
service httpd restart

echo "Testing for ffmpeg extension, if output is null then something is wrong.  Most likely php.ini needs to be fixed, see http://watters.ws/wiki/index.php/FFMPEG_and_ffmpeg-php for instructions."
php -i | grep ffmpeg

# Install test files
wget -c http://mw.liquidweb.com/rpms/centos4/ffmpeg_stuff/post-install_ffmpeg_tests.tgz
tar -C /usr/local/apache/htdocs -xzf post-install_ffmpeg_tests.tgz
chown nobody:nobody /usr/local/apache/htdocs/post-install_ffmpeg_tests/*

echo "To test the install use the following URL:"
echo "${IP}/post-install_ffmpeg_tests/index.php"

# Clean up
#rm -fv $0 
exit 0
