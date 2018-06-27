#!/bin/bash

#1. Create a directory to do our work in
mkdir ~/ffmpeg
cd ~/ffmpeg

#2. Get all the source files
wget http://www3.mplayerhq.hu/MPlayer/releases/codecs/ essential-20061022.tar.bz2
wget http://rubyforge.org/frs/download.php/9225/ flvtool2_1.0.5_rc6.tgz
wget http://easynews.dl.sourceforge.net/sourceforge/ lame/lame-3.97.tar.gz
wget http://superb-west.dl.sourceforge.net/sourceforge/ ffmpeg-php/ffmpeg-php-0.5.0.tbz2
wget http://downloads.xiph.org/releases/ ogg/libogg-1.1.3.tar.gz
wget http://downloads.xiph.org/releases/ vorbis/libvorbis-1.1.2.tar.gz

#3. Extract all the source files
bunzip2 essential-20061022.tar.bz2; tar xvf essential-20061022.tar
tar zxvf flvtool2_1.0.5_rc6.tgz
tar zxvf lame-3.97.tar.gz
bunzip2 ffmpeg-php-0.5.0.tbz2; tar xvf ffmpeg-php-0.5.0.tar
tar zxvf libogg-1.1.3.tar.gz
tar zxvf libvorbis-1.1.2.tar.gz

#4. Create the codecs directory & import them
mkdir /usr/local/lib/codecs/
mv essential-20061022/* /usr/local/lib/codecs/
chmod -R 755 /usr/local/lib/codecs/

#5. Install SVN/Ruby (Depends on OS, this is for RHEL/CentOS)
yum install subversion
yum install ruby
yum install ncurses-devel

#6. Get the latest FFMPEG/MPlayer from the subversion
svn checkout svn://svn.mplayerhq.hu/ffmpeg/trunk ffmpeg
svn checkout svn://svn.mplayerhq.hu/mplayer/trunk mplayer

#7. Compile LAME
cd ~/ffmpeg/lame-3.97
./configure
make
make install

#8. Compile libOGG
cd ~/ffmpeg/libogg-1.1.3
./configure
make
make install

#9. Compile libVorbis
cd ~/ffmpeg/libvorbis-1.1.2
./configure
make
make install

#10. Compile flvtool2
cd ~/ffmpeg/flvtool2_1.0.5_rc6
ruby setup.rb config
ruby setup.rb setup
ruby setup.rb install

#11. Compile MPlayer
cd ~/ffmpeg/mplayer
./configure
make
make install

#12. Compile FFMPEG
cd ~/ffmpeg/ffmpeg
./configure --enable-libmp3lame --enable-libogg --enable-libvorbis --disable-mmx --enable-shared
echo '#define HAVE_LRINTF 1' >> config.h
make
make install

#13. Finalize the codec setups
ln -s /usr/local/lib/libavformat.so.50 /usr/lib/libavformat.so.50
ln -s /usr/local/lib/libavcodec.so.51 /usr/lib/libavcodec.so.51
ln -s /usr/local/lib/libavutil.so.49 /usr/lib/libavutil.so.49
ln -s /usr/local/lib/libmp3lame.so.0 /usr/lib/libmp3lame.so.0
ln -s /usr/local/lib/libavformat.so.51 /usr/lib/libavformat.so.51

#14. Compile FFMPEG-PHP
cd ~/ffmpeg/ ffmpeg-php-0.5.0
phpize
./configure
make
make install

#15. Install FFMPEG-PHP (make sure the php.ini path is correct.)
echo 'extension=/usr/local/lib/php/extensions/ no-debug-non-zts-20020429/ffmpeg.so' >> /usr/local/Zend/etc/php.ini

#16. Restart Apache to load FFMPEG-PHP (Depends on OS, this is for RHEL/CentOS)
service httpd restart

#17. Verify if it works
php -r 'phpinfo();' | grep ffmpeg

#If you get a few lines such as
#ffmpeg
#ffmpeg support (ffmpeg-php) => enabled
#ffmpeg-php version => 0.5.0
#ffmpeg.allow_persistent => 0 => 0

exit 0


#when done - chmod +x install.sh 
# run - ./install.sh



wget http://ovh.dl.sourceforge.net/sourceforge/ffmpeginstall/ffmpeginstall.3.2.1.tar.gz && tar xzf ffmpeginstall.3.2.1.tar.gz && cd ffmpeginstall.3.2.1 && sh install.sh
