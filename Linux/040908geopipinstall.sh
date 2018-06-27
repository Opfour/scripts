#!bin/bash

wget http://www.maxmind.com/download/geoip/api/c/GeoIP-1.4.3.tar.gz  
wget http://www.maxmind.com/download/geoip/api/mod_geoip2/mod_geoip2_1.2.0.tar.gz  
wget http://www.maxmind.com/download/geoip/database/GeoIP.dat.gz  
gunzip GeoIP.dat.gz  
tar xzf GeoIP-1.4.3.tar.gz -C /usr/local/src  
tar xzf mod_geoip2_1.2.0.tar.gz -C /usr/local/src  
cd /usr/local/src/GeoIP-1.4.3/  
./configure --prefix=/usr/local/geoip  
make  
make install    
cd /usr/local/src/mod_geoip2_1.2.0/  
apxs2 -i -a -L/usr/local/geoip/lib -I/usr/local/geoip/include -lGeoIP -c mod_geoip.c  cp ~/GeoIP.dat /usr/local/geoip/share/GeoIP/    
echo '/usr/local/geoip/lib' >> /etc/ld.so.conf.d/apache  

# Debian-specific (but you must have the same configuration directive to this module - ways to adapt, of course) 
# Remove the LoadModule line File / etc/apache2/httpd.conf 

echo 'LoadModule geoip_module /usr/lib/apache2/modules/mod_geoip.so' > /etc/apache2/mods-available/geoip.load  
cat > /etc/apache2/mods-available/geoip.conf  
GeoIPEnable On  
GeoIPDBFile /usr/local/geoip/share/GeoIP/GeoIP.dat  ^D  a2enmod geoip  
# End  
ldconfig  /etc/init.d/apache2 force-reload 
# Restart Apache 
Cd wget http://www.maxmind.com/download/geoip/api/c/GeoIP-1.4.3.tar.gz 
wget http://www.maxmind.com/download/geoip/api/mod_geoip2/mod_geoip2_1. 2.0.tar.gz 
wget http://www.maxmind.com/download/geoip/database/GeoIP.dat.gz 
gunzip GeoIP.dat.gz 
tar xzf GeoIP-1.4.3.tar.gz-C / usr / local / src 
tar xzf mod_geoip2_1.2.0.tar.gz-C / usr / local / src cd / usr/local/src/GeoIP-1.4.3 /
./configure - prefix = / usr / local / geoip 
make 
make install 
cd / usr/local/src/mod_geoip2_1.2.0 / 
apxs2-i-a -L/usr/local/geoip/lib -I/usr/local/geoip/include-lGeoIP-c mod_geoip.c cp ~ / GeoIP.dat / usr / local / geoip / share / GeoIP / echo '/ usr / local / geoip / lib'>> / etc / ld.so.conf.d / apache 
# Debian-specific (but you must have the same configuration directive to this module - ways to adapt, of course) 
# Remove the LoadModule line File / etc/apache2/httpd.conf 
echo 'LoadModule geoip_module / usr/lib/apache2/modules/mod_geoip.so'> / etc/apache2/mods-available / geoip.load 
cat> / etc/apache2/mods-available/geoip.conf GeoIPEnable On GeoIPDBFile / usr / local / geoip / share / GeoIP / GeoIP.dat ^ D a2enmod geoip 
# End 
ldconfig / etc/init.d/apache2 force-reload 
# Restarting Apache 

exit 0

