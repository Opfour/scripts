#! /bin/sh

wget http://www.maxmind.com/download/geoip/api/c/GeoIP-1.4.4.tar.gz
tar -xzvf GeoIP-1.4.4.tar.gz
cd GeoIP-1.4.4
./configure
make
make check
make install

exit 0

#/usr/lib/httpd/modules/mod_geoip.so
