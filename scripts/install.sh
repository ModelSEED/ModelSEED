#!/bin/sh

# check for readlink, if not available warn user to use absolute paths

TB_LINK="https://github.com/ModelSEED/ModelSEED/tarball/master" # other branches?
DEP_LINK="http://bioseed.mcs.anl.gov/~pfrybar/msdist"

# check if running as root (sudo)
ROOT=0
if [ "$(id -u)" -eq "0" ]; then
    ROOT=1
fi

# parse the options (-t, -d, and -i)
VERBOSE=0
TYPE=user
SET_INSTALL=0
if [ $ROOT -eq 1 ]; then
    LOCAL=/usr/local
    INSTALL=/usr/local
else
    LOCAL=$HOME/local
    INSTALL=$HOME/local
fi

while getopts ":hvt:l:i:" optname
do
    case "$optname" in
        "h")
            # print usage
            echo "usage: "
            exit
            ;;
        "v")
            # verbose
            VERBOSE=1
            ;;
        "t")
            # one of 'user' or 'dev'
            if [ $OPTARG = "user" ]; then
                TYPE=user
            elif [ $OPTARG = "dev" ]; then
                TYPE=dev
            else
                echo "Valid type (-t) options are 'user' and 'dev'."
                exit
            fi
            ;;
        "l")
            LOCAL=`readlink -f $OPTARG`
            ;;
        "i")
            INSTALL=`readlink -f $OPTARG`
            SET_INSTALL=1
            ;;
        "?")
            echo "Unknown option -$OPTARG"
            # print usage
            exit
            ;;
        ":")
            echo "No value for option -$OPTARG"
            # print usage
            exit
            ;;
    esac
done

if [ $TYPE = "user" ]; then
    while true; do
        echo "\nInstalling ModelSEED into '$LOCAL', do you want to continue? (y/n)"
        read -p "" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* )
                echo "Cancelling, 'install.sh -h' for options"
                exit
                ;;
            * ) echo "Please answer yes or no.";;
        esac
    done
else
    # set install directory to `pwd`/ModelSEED if not set
    if [ $SET_INSTALL -eq 0 ]; then
        INSTALL=`pwd`/ModelSEED
    fi

    while true; do
        echo "\nInstalling ModelSEED into '$INSTALL', and dependencies into '$LOCAL', do you want to continue? (y/n)"
        read -p "" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* )
                echo "Cancelling, 'install.sh -h' for options"
                exit
                ;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

OUT="/dev/null"
if [ $VERBOSE -eq 1 ]; then
    OUT="/dev/stdout"
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

update_progress(){
    PROGRESS=`expr $PROGRESS + 1`
    echo -n "$PROGRESS" > .progress
}

echo "Beginning ModelSEED installation..."
echo "\tinstall type:" $TYPE > $OUT

if [ $ROOT -eq 1 ]; then
    echo "\troot install: yes" > $OUT
else
    echo "\troot install: no" > $OUT
fi

echo "\tlocal dir:" $LOCAL > $OUT
echo "\tinstall dir:" $INSTALL > $OUT

if ! [ -d /tmp/MSInstall ]; then
    mkdir /tmp/MSInstall
fi

cd /tmp/MSInstall

if ! [ -f .progress ]; then
    echo -n "0" > .progress
fi

PROGRESS=`cat .progress`

# PROGRESS
# 0 - install glpk (should allow cplex eventually)
# 1 - install MFAToolkit
# 2 - install MS manual dependencies (cpanm, zlib, libxml2, XML::LibXML)
# 3 - install MS perl dependencies (via Build.PL)
# 4 - install MS
# 5 - run tests?

if [ $PROGRESS -eq 0 ]; then
    update_progress
fi

if [ $PROGRESS -eq 1 ]; then
    update_progress
fi

if [ $PROGRESS -eq 2 ]; then
    CPANM="cpanm"
    if ! [ `which cpanm` ]; then
        # download cpanm.pl
        if ! [ -f cpanm.pl ]; then
            $UA cpanm.pl $DEP_LINK/cpanm.pl 1>$OUT 2>&1
            perl cpanm.pl -l $LOCAL App::cpanminus 1>$OUT 2>&1
            CPANM=$LOCAL/bin/cpanm
        fi
    fi

    echo "main(){}" > test.c
    `cc -lxml2 test.c 1>/dev/null 2>&1`
    if [ $? -ne 0 ]; then
        # need to install libxml2 and XML::LibXML manually
        # first check if we need to install zlib too
        `cc -lz test.c 1>/dev/null 2>&1`
        if [ $? -ne 0 ]; then
            # install zlib
            if ! [ -d zlib ]; then
                $UA zlib.tgz $DEP_LINK/zlib.tgz 1>$OUT 2>&1
                tar -xzvf zlib.tgz 1>$OUT 2>&1
            fi

            cd zlib
            ./configure --prefix=$LOCAL 1>$OUT 2>&1
            make 1>$OUT 2>&1
            make install 1>$OUT 2>&1
            cd ..
        fi

        # install libxml2
        if ! [ -d libxml2 ]; then
            $UA libxml2.tgz $DEP_LINK/libxml2.tgz 1>$OUT 2>&1
            tar -xzvf libxml2.tgz 1>$OUT 2>&1
        fi

        cd libxml2
        ./configure --prefix=$LOCAL 1>$OUT 2>&1
        make 1>$OUT 2>&1
        make install 1>$OUT 2>&1
        cd ..

        # install XML::LibXML
        if ! [ -d XML-LibXML ]; then
            $UA XML-LibXML.tgz $DEP_LINK/XML-LibXML.tgz 1>$OUT 2>&1
            tar -xzvf XML-LibXML.tgz 1>$OUT 2>&1
        fi

        cd XML-LibXML
        perl Makefile.PL XMLPREFIX=$LOCAL INSTALL_BASE=$LOCAL 1>$OUT 2>&1
        make 1>$OUT 2>&1
        make install 1>$OUT 2>&1
        cd ..
    fi

    update_progress
fi

if [ $PROGRESS -eq 3 ]; then
    # download ModelSEED tarball or git clone
    if ! [ -d ModelSEED ]; then
        $UA ModelSEED.tgz $TB_LINK 1>$OUT 2>&1
        tar -xzvf ModelSEED.tgz 1>$OUT 2>&1
        mv ModelSEED-* ModelSEED
    fi

    cd ModelSEED
    perl Build.PL
    ./Build installdeps --cpan_client 'cpanm' --install_base $LOCAL
    ./Build install --install_base $LOCAL
fi

