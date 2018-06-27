#!/bin/sh
#
# Copyright (C) 2005 Server Monkeys Services, Richard Gannon and Martynas Bendorius.  All Rights Reserved.
#
# Author: Richard Gannon <rich@servermonkeys.com> and Martynas Bendorius <martynas@e-vaizdas.net>
#
# For questions, comments, and support, please visit:
# www.servermonkeys.com
#
# Easy Linux Security (ELS), v. 1.7.0
#
########################################################################################
#    Easy Linux Security (ELS) is free software; you can redistribute it and/or modify #
#    it under the terms of the GNU General Public License as published by              #
#    the Free Software Foundation; either version 2 of the License, or                 #
#    (at your option) any later version.                                               #
#                                                                                      #
#    This program is distributed in the hope that it will be useful,                   #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of                    #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                     #
#    GNU General Public License for more details.                                      #
#                                                                                      #
#    You should have received a copy of the GNU General Public License                 #
#    along with this program; if not, write to the Free Software                       #
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA        #
########################################################################################
##

INSTALLDIR=/usr/local/els
MIRROR=http://servermonkeys.com/projects/els

if [ -d /usr/local/rgsecurity ]; then
	mv /usr/local/rgsecurity $INSTALLDIR
	rm -f $INSTALLDIR/rgsecurity.sh
	rm -f $INSTALLDIR/updater.sh
else
	mkdir $INSTALLDIR
	mkdir $INSTALLDIR/src
	mkdir $INSTALLDIR/bakfiles
fi

wget -q --output-document=$INSTALLDIR/versions $MIRROR/versions
if [ "`grep els-core $INSTALLDIR/versions`" = "" ]; then
	echo "Failed to download versions file."
	echo "Aborting."
	rm -f $INSTALLDIR/versions
	exit
fi
echo "Downloading..."
wget -q --output-document=$INSTALLDIR/src/els.tar.gz $MIRROR/els.tar.gz
echo "Done."
if [ "`md5sum $INSTALLDIR/src/els.tar.gz | cut -d ' ' -f 1`" = "`grep els-core -m1 $INSTALLDIR/versions | cut -d ':' -f 3`" ]; then
	echo "MD5 valid."
else
	echo "MD5 invalid. Aborting."
	exit
fi
cd $INSTALLDIR/src
echo "Extracting..."
tar -zxf els.tar.gz
cd els/
mv * $INSTALLDIR
chmod -R 700 $INSTALLDIR
cd $INSTALLDIR/src
echo "Done."
rm -rf els.tar.gz els/
rm -f $INSTALLDIR/versions
ln -s /usr/local/els/els.sh /usr/local/bin/els

echo
echo "Easy Linux Security (ELS) successfully installed in $INSTALLDIR"
echo "Type 'els --help' for available options."

exit 0

