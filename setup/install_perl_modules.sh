#!/bin/bash

echo "install perl modules"

MODULES=(
	Archive::Zip
	CGI::Session
	Crypt::SaltedHash
	Digest::MD5
	Digest::SHA
	Encode
	File::Path
	File::Spec
	Getopt::Long
	HTML::Strip
	IPC::Run3
	JSON::XS
	List::Util
	Net::LDAP
	NetAddr::IP::Util
	parent
	Plack::Test::Server
	Plack::Middleware::XForwardedFor
	Regexp::IPv6
	String::MkPasswd
	Template
	Test::Selenium::Remote::Driver
	Test::More
	Test::Differences
	Text::Template
	Time::HiRes
	XML::XPath
	Cpanel::JSON::XS
	Selenium::Chrome
)

MODUELS_SIZE=${#MODULES[@]}
FAILED=0

FAILED_MODULES=()

#for VALUE in "${MODULES[@]}" 
for ((i=0; i<$MODUELS_SIZE; i++))
do
	echo -e "\n[$(($i+1))/$MODUELS_SIZE]"
	cpanm ${MODULES[i]}
	if [ $? -gt 0 ] 
	then
		FAILED_MODULES+=(${MODULES[i]})
	fi
done

echo -e "\ndone\n"

if [ ${#FAILED_MODULES[@]} -ne 0 ]
then
	echo "[${#FAILED_MODULES[@]}/$MODUELS_SIZE] module(s) failed to install"
	echo -e "try to install following modules manually:\n"
	for ((i=0; i<${#FAILED_MODULES[@]}; i++))
	do
		echo ${FAILED_MODULES[i]}
		exit -1
	done
else
	echo "all modules are installed"
	exit 0
fi
