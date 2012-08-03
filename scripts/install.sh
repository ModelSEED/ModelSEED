#!/bin/sh

# this attempts to install the ModelSEED and all dependencies

# assume using current dir, ask later for install dir

# check if mac os x, if no gcc/make then need to download xcode

# can either clone the repository, or download a tarball
#git clone https://github.com/ModelSEED/Model-SEED-core.git ModelSEEDCore

# should this take options from: command line, script, or prompt?

HOST=http://bioseed.mcs.anl.gov/~pfrybar/msdist
GLOBAL=0             # option
DIR=`pwd`/ModelSEED  # option
LOCAL=$DIR/local     # option
LOG=`pwd`/build.log  # option

# todo: echo parameters into log file
echo "Beginning ModelSEED installation" > $LOG

# Check for required applications
ERRORS=0
for PROGRAM in perl cc make
do
    if ! [ `which $PROGRAM` ];
    then
        ERRORS=1
        echo "Could not find required program: '$PROGRAM'."
    fi
done

# stop after errors if we got them
if [ $ERRORS -eq 1 ];
then
    echo "Please install program(s) listed above and try again."
    exit
fi

# setup download client (curl or wget)
if [ `which curl` ];
then
    UA='curl -o'
elif [ `which wget` ];
then
    UA='wget -O'
else
    echo "Please install either 'curl' or 'wget' and try again."
exit
fi

download_file(){
    echo -n "Downloading file '$1' ..."
    `$UA $1 $HOST/$1 1>>$LOG 2>&1`
    echo " finished!"
}

check_error(){
    if [ $? -ne 0 ];
    then
	echo "Error running install, check $LOG for details"
	exit 2
    fi
}

# download source code (todo: git or tarball)
#if ! [ -f ModelSEED.tgz ];
#then
#    download_file ModelSEED.tgz
#fi

#tar -zxf ModelSEED.tgz

cd ModelSEED
mkdir local
mkdir src

# install cpanm if not found
cd src
if ! [ `which cpanm` ];
then
    download_file cpanm.pl
    echo -n "Installing cpanm ..."
    if [ $GLOBAL -eq 1 ];
    then
	sudo perl cpanm.pl App::cpanminus 1>>$LOG 2>&1; check_error
    else
	perl cpanm.pl -l $LOCAL App::cpanminus local::lib 1>>$LOG 2>&1; check_error
	eval $(perl -I$LOCAL/lib/perl5 -Mlocal::lib=$LOCAL) 1>>$LOG 2>&1; check_error
    fi
    echo " finished!"
fi

# following packages need external libraries installed:
#   - XML::Parser - expat
#   - XML::LibXML - xml2 (which requires zlib, -lz)
echo "main(){}" > test.c

# `cc -lexpat test.c 1>/dev/null 2>&1`
# if [ $? -ne 0 ];
# then
#     # need to install expat and XML::Parser manually
#     download_file expat.tgz
#     tar -xzf expat.tgz
#     cd expat
#     echo -n "Building expat ..."
#     if [ $GLOBAL -eq 1 ];
#     then
# 	./configure 1>>$LOG 2>&1; check_error
# 	make 1>>$LOG 2>&1; check_error
# 	sudo make install 1>>$LOG 2>&1; check_error
#     else
# 	./configure --prefix=$LOCAL 1>>$LOG 2>&1; check_error
# 	make 1>>$LOG 2>&1; check_error
# 	make install 1>>$LOG 2>&1; check_error
#     fi
#     echo " finished!"
#     cd ..

#     download_file XML-Parser.tgz
#     tar -xzf XML-Parser.tgz
#     cd XML-Parser
#     echo -n "Building XML::Parser ..."
#     if [ $GLOBAL -eq 1 ];
#     then
# 	perl Makefile.PL 1>>$LOG 2>&1; check_error
# 	make 1>>$LOG 2>&1; check_error
# 	sudo make install 1>>$LOG 2>&1; check_error
#     else
# 	perl Makefile.PL EXPATLIBPATH=$LOCAL/lib EXPATINCPATH=$LOCAL/include INSTALL_BASE=$LOCAL 1>>$LOG 2>&1; check_error
# 	make 1>>$LOG 2>&1; check_error
# 	make install 1>>$LOG 2>&1; check_error
#     fi
#     echo " finished!"
#     cd ..
# fi

`cc -lxml2 test.c 1>/dev/null 2>&1`
if [ $? -ne 0 ];
then
    # need to install libxml2 and XML::LibXML manually
    # first check if we need to install zlib too
    `cc -lz test.c 1>/dev/null 2>&1`
    if [ $? -ne 0 ];
    then
        # install zlib
	download_file zlib.tgz
	tar -xzf zlib.tgz
	cd zlib
	echo -n "Building zlib ..."
	if [ $GLOBAL -eq 1 ];
	then
	    ./configure 1>>$LOG 2>&1; check_error
	    make 1>>$LOG 2>&1; check_error
	    sudo make install 1>>$LOG 2>&1; check_error
	else
	    ./configure --prefix=$LOCAL 1>>$LOG 2>&1; check_error
	    make 1>>$LOG 2>&1; check_error
	    make install 1>>$LOG 2>&1; check_error
	fi
	echo " finished!"
	cd ..
    fi

    # install libxml2
    download_file libxml2.tgz
    tar -xzf libxml2.tgz
    cd libxml2
    echo -n "Building libxml2 (may take a few minutes) ..."
    if [ $GLOBAL -eq 1 ];
    then
	./configure 1>>$LOG 2>&1; check_error
	make 1>>$LOG 2>&1; check_error
	sudo make install 1>>$LOG 2>&1; check_error
    else
	./configure --prefix=$LOCAL 1>>$LOG 2>&1; check_error
	make 1>>$LOG 2>&1; check_error
	make install 1>>$LOG 2>&1; check_error
    fi
    echo " finished!"
    cd ..

    # install XML::LibXML
    download_file XML-LibXML.tgz
    tar -xzf XML-LibXML.tgz
    cd XML-LibXML
    echo -n "Building XML::LibXML ..."
    if [ $GLOBAL -eq 1 ];
    then
	perl Makefile.PL 1>>$LOG 2>&1; check_error
	make 1>>$LOG 2>&1; check_error
	sudo make install 1>>$LOG 2>&1; check_error
    else
	perl Makefile.PL XMLPREFIX=$LOCAL INSTALL_BASE=$LOCAL 1>>$LOG 2>&1; check_error
	make 1>>$LOG 2>&1; check_error
	make install 1>>$LOG 2>&1; check_error
    fi
    echo " finished!"
    cd ..
fi

exit

# now install carton and try to install dependencies
cd ..
    echo -n "Installing Perl dependencies (will take a few minutes) ..."
if [ $GLOBAL -eq 1 ];
then
    sudo cpanm Carton 1>>$LOG 2>&1; check_error
    sudo carton install 1>>$LOG 2>&1; check_error
else
    cpanm -l $LOCAL Carton 1>>$LOG 2>&1; check_error
    carton install 1>>$LOG 2>&1; check_error
fi

echo " finished!"
echo "ModelSEED installation completed successfully!"