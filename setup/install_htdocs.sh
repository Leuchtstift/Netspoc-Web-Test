#!/bin/bash

ALL_OKAY=0

echo "new folder 'htdocs'"
mkdir htdocs
cd "$_"
echo "get extjs4"
git clone https://github.com/xantus/ext-js-gpl
if [ $? -eq 0 ]
then
	mv /home/marker/test/htdocs/ext-js-gpl /home/marker/test/htdocs/extjs4
else
	echo "failed to clone extjs4 from clone https://github.com/xantus/ext-js-gpl"
	ALL_OKAY=-1
fi

echo "get silk-icons"
mkdir silk-icons 
cd "$_"
wget http://www.famfamfam.com/lab/icons/silk/famfamfam_silk_icons_v013.zip
# i choose to use a perl module to unzip, because i know for sure you have perl installed :)
#bsdtar -xf famfamfam_silk_icons_v013.zip
echo "install perl module to extract silk-icons"
cpanm Archive::Extract
perl ../../unzipdis.pm famfamfam_silk_icons_v013.zip
if [ $? -eq 0 ]
then
	rm famfamfam_silk_icons_v013.zip
else
	echo "htdocs/silk-icons/famfamfam_silk_icons_v013.zip needs to get extracted manually"
	ALL_OKAY=-1
fi

cd ../..

exit $ALL_OKAY