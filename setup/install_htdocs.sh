#!/bin/bash

ALL_OKAY=0
cd ~
echo "new folder 'htdocs'"
mkdir htdocs
cd "$_"
echo "get extjs4"
git clone https://github.com/xantus/ext-js-gpl &&
	mv -v ext-js-gpl/ext-4.2.1 extjs4 &&
	rm -rf ext-js-gpl ||
	echo "failed to clone extjs4 from clone https://github.com/xantus/ext-js-gpl" &&
	ALL_OKAY=-1

echo "get silk-icons"
mkdir silk-icons 
mkdir tempo
cd "$_"
wget http://www.famfamfam.com/lab/icons/silk/famfamfam_silk_icons_v013.zip
wget https://download.damieng.com/iconography/SilkCompanion1.zip

# i choose to use a perl module to unzip, because i know for sure you have perl installed :)
#bsdtar -xf famfamfam_silk_icons_v013.zip
echo "install perl module to extract silk-icons"
cpanm Archive::Extract

a=`find ~/ -name unzipdis.pm` &&
	a=($a) &&
	perl $a famfamfam_silk_icons_v013.zip SilkCompanion1.zip &&
	rm famfamfam_silk_icons_v013.zip SilkCompanion1.zip &&
	cd .. &&
	mv  -v tempo/icons/* silk-icons/ &&
	rm -r tempo &&
	cd .. ||
	echo "htdocs/silk-icons/famfamfam_silk_icons_v013.zip and/or SilkCompanion1.zip needs to get extracted manually. Move all icons to htdocs/silk-icons." ||
	ALL_OKAY=-1

exit $ALL_OKAY