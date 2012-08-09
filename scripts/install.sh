#!/bin/sh

# check for readlink, if not available warn user to use absolute paths

TB_LINK="http://bioseed.mcs.anl.gov/~pfrybar/msdist/ModelSEED.tgz" # how to deal with versions/branches
DEP_LINK="http://bioseed.mcs.anl.gov/~pfrybar/msdist"

# check if running as root (sudo)
ROOT=0
if [ "$(id -u)" -eq 0 ]; then
    ROOT=1
fi

# options:
# -h  help
# -v  verbose, all output goes to command line
# -y  yes, no confirm
# -c  clean, remove /tmp/MSInstall completely and start fresh
# -t  install type, either user or dev
# -l  local dir, where to install dependencies
# -i  install dir, where to put MFAToolkit and ModelSEED (for dev install only)

# -r  force root, useful for rootless systems like Cygwin (TODO)

# parse the options
VERBOSE=0
CONFIRM=1
TYPE=user
if [ $ROOT -eq 1 ]; then
    LOCAL="-"
    INSTALL="-"
else
    LOCAL=$HOME/local
    INSTALL=$HOME/local
fi

while getopts ":hvyct:l:i:" optname
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
	"y")
	    # yes
	    CONFIRM=0
	    ;;
	"c")
	    # clean
	    if [ -d /tmp/MSInstall ]; then
		rm -rf /tmp/MSInstall
	    fi
	    ;;
        "t")
            # one of 'user' or 'dev'
            if [ $OPTARG = "user" ]; then
                TYPE=user
            elif [ $OPTARG = "dev" ]; then
                TYPE=dev
            else
                echo "Valid type (-t) options are 'user' and 'dev'."
                exit 2
            fi
            ;;
        "l")
            LOCAL=`readlink -f $OPTARG`
            ;;
        "i")
            INSTALL=`readlink -f $OPTARG`
            ;;
        "?")
            echo "Unknown option -$OPTARG"
            # print usage
            exit 2
            ;;
        ":")
            echo "No value for option -$OPTARG"
            # print usage
            exit 2
            ;;
    esac
done

if [ $TYPE = "user" ]; then
    while true; do
        echo ""
        echo "Installing ModelSEED as a user into '$LOCAL', do you want to continue? (y/n)"
	if [ $CONFIRM -eq 0 ]; then
	    echo "y"
	    break
	fi
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
    if [ $INSTALL = "-" ]; then
        INSTALL=`pwd`
    fi

    while true; do
        echo
        echo "Installing ModelSEED as a developer into '$INSTALL', do you want to continue? (y/n)"
	if [ $CONFIRM -eq 0 ]; then
	    echo "y"
	    break
	fi
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

# setup environment if LOCAL was set
if [ $LOCAL != "-" ]; then
    export PATH=$LOCAL/bin:$PATH
    if [ -n "$PERL5LIB" ]; then
	export PERL5LIB=$LOCAL/lib/perl5:$PERL5LIB
    else
	export PERL5LIB=$LOCAL/lib/perl5
    fi
fi

# setup download client (curl or wget)
if which curl 1>/dev/null 2>&1; then
    UA='curl -o'
else
    if which wget 1>/dev/null 2>&1; then
	UA='wget -O'
    else
	echo "Please install either 'curl' or 'wget' and try again."
    fi
fi

# check for other requirements
ERROR=0
for PROGRAM in perl cc make
do
    if ! which $PROGRAM 1>/dev/null 2>&1; then
        ERROR=1
        echo "Could not find required program: '$PROGRAM'."
    fi
done

if [ $TYPE = "dev" ]; then
    if ! which git 1>/dev/null 2>&1; then
	ERROR=1
	echo "Could not find required program: 'git'."
    fi
fi

# stop if there is an error
if [ $ERROR -eq 1 ]; then
    echo "Please install program(s) listed above and try again."
    exit 2
fi

# make the install directory if it doesn't exist
if [ $TYPE = "dev" ]; then
    if [ ! -d $INSTALL ]; then
	mkdir -p $INSTALL
    fi
fi

update_progress(){
    PROGRESS=`expr $PROGRESS + 1`
    echo -n "$PROGRESS" > .progress
}

check_error(){
    if [ $? -ne 0 ];
    then
	echo "Error running install, use -v for additional information"
	exit 2
    fi
}

echo ""
echo "Beginning ModelSEED installation"
echo "    install type:" $TYPE > $OUT

if [ $ROOT -eq 1 ]; then
    echo "    root install: yes" > $OUT
else
    echo "    root install: no" > $OUT
fi

echo "    local dir:" $LOCAL > $OUT
echo "    install dir:" $INSTALL > $OUT

if [ ! -d /tmp/MSInstall ]; then
    mkdir /tmp/MSInstall
fi

cd /tmp/MSInstall

# check for dependencies (libxml2, glpk)
echo "Installing dependencies"
echo "main(){}" > test.c

# check for glpk
if ! cc -lglpk test.c 1>/dev/null 2>&1; then
    echo "  -> installing glpk"
    if [ ! -d glpk ]; then
	$UA glpk.tgz $DEP_LINK/glpk.tgz 1>$OUT 2>&1; check_error
	tar -xzvf glpk.tgz 1>$OUT 2>&1; check_error
    fi

    cd glpk
    if [ ! -f .local ] || [ $LOCAL != `cat .local` ]; then
	if [ $LOCAL = "-" ]; then
	    ./configure 1>$OUT 2>&1; check_error
	else
	    ./configure --prefix=$LOCAL 1>$OUT 2>&1; check_error
	fi
	echo -n $LOCAL > .local
    fi
    make 1>$OUT 2>&1; check_error
    make install 1>$OUT 2>&1; check_error
    cd ..
fi

# check for XML::LibXML (plus libxml2 and zlib if necessary)
if ! cc -lxml2 test.c 1>/dev/null 2>&1; then
    # first check if we need to install zlib too
    if ! cc -lz test.c 1>/dev/null 2>&1; then
        # install zlib
	echo "  -> installing zlib"
	if [ ! -d zlib ]; then
            $UA zlib.tgz $DEP_LINK/zlib.tgz 1>$OUT 2>&1; check_error
            tar -xzvf zlib.tgz 1>$OUT 2>&1; check_error
	fi

	cd zlib
	if [ ! -f .local ] || [ $LOCAL != `cat .local` ]; then
	    if [ $LOCAL = "-" ]; then
		./configure 1>$OUT 2>&1; check_error
	    else
		./configure --prefix=$LOCAL 1>$OUT 2>&1; check_error
	    fi
	    echo -n $LOCAL > .local
	fi
	make 1>$OUT 2>&1; check_error
	make install 1>$OUT 2>&1; check_error
	cd ..
    fi

    # install libxml2
    echo "  -> installing libxml2"
    if [ ! -d libxml2 ]; then
	$UA libxml2.tgz $DEP_LINK/libxml2.tgz 1>$OUT 2>&1; check_error
	tar -xzvf libxml2.tgz 1>$OUT 2>&1; check_error
    fi

    cd libxml2
    if [ ! -f .local ] || [ $LOCAL != `cat .local` ]; then
	if [ $LOCAL = "-" ]; then
	    ./configure 1>$OUT 2>&1; check_error
	else
	    ./configure --prefix=$LOCAL 1>$OUT 2>&1; check_error
	fi
	echo -n $LOCAL > .local
    fi
    make 1>$OUT 2>&1; check_error
    make install 1>$OUT 2>&1; check_error
    cd ..
fi

# download cpanm.pl
if [ ! -f cpanm.pl ]; then
    $UA cpanm.pl $DEP_LINK/cpanm.pl 1>$OUT 2>&1; check_error
fi

echo "  -> installing perl dependencies (this will take a few minutes)"

# download ModelSEED source code
if [ ! -d ModelSEED ]; then
    if [ $TYPE = "dev" ]; then
	git clone https://github.com/ModelSEED/ModelSEED.git 1>$OUT 2>&1; check_error
    else
        $UA ModelSEED.tgz $TB_LINK 1>$OUT 2>&1; check_error
        tar -xzvf ModelSEED.tgz 1>$OUT 2>&1; check_error
    fi
fi

cd ModelSEED
perl Build.PL 1>$OUT 2>&1; check_error

if [ ! -f .local ] || [ $LOCAL != `cat .local` ]; then
    if [ $LOCAL = "-" ]; then
	./Build installdeps --cpan_client "perl /tmp/MSInstall/cpanm.pl -n" 1>$OUT 2>&1; check_error
    else
	./Build installdeps --cpan_client "perl /tmp/MSInstall/cpanm.pl -n -l $LOCAL" 1>$OUT 2>&1; check_error
    fi
    echo -n $LOCAL > .local
fi
cd ..

echo "Installing core code"

echo "  -> installing MFAToolkit"
if [ ! -d MFAToolkit ]; then
    if [ $TYPE = "dev" ]; then
	git clone https://github.com/ModelSEED/MFAToolkit.git 1>$OUT 2>&1; check_error 1>$OUT 2>&1; check_error
    else
	$UA MFAToolkit.tgz $DEP_LINK/MFAToolkit.tgz 1>$OUT 2>&1; check_error
	tar -xzvf MFAToolkit.tgz 1>$OUT 2>&1; check_error
    fi
fi

cd MFAToolkit
if [ ! -f .local ] || [ $LOCAL != `cat .local` ]; then
    if [ $LOCAL = "-" ]; then
	make 1>$OUT 2>&1; check_error
    else
	INC="-I$LOCAL/include -L$LOCAL/lib" LD_RUN_PATH=$LOCAL/lib make 1>$OUT 2>&1; check_error
    fi
    echo -n $LOCAL > .local
fi

# install
if [ $TYPE = "user" ]; then
    if [ $LOCAL = "-" ]; then
	make deploy-mfatoolkit 1>$OUT 2>&1; check_error
    else
	TARGET=$LOCAL make deploy-mfatoolkit 1>$OUT 2>&1; check_error
    fi    
else
    # copy to install dir
    if [ -d $INSTALL/MFAToolkit ]; then
	echo "Error, '$INSTALL/MFAToolkit' directory already exists."
	echo "  Please rename or delete and try again."
	exit 2
    fi

    cp -r ../MFAToolkit $INSTALL/MFAToolkit
fi
cd ..

echo "  -> installing ModelSEED"
cd ModelSEED
if [ $TYPE = "user" ]; then
    if [ $LOCAL = "-" ]; then
	if [ -d /usr/local/bin ]; then
	    ./Build install --install_path script=/usr/local/bin 1>$OUT 2>&1; check_error
	else
            # shouldn't happen, but maybe some weird linux version, install to /usr/bin
	    ./Build install --install_path script=/usr/bin 1>$OUT 2>&1; check_error
	fi
    else
	./Build install --install_base $LOCAL 1>$OUT 2>&1; check_error
    fi
else
    # copy to install dir
    if [ -d $INSTALL/ModelSEED ]; then
	echo "Error, '$INSTALL/ModelSEED' directory already exists."
	echo "  Please rename or delete and try again."
	exit 2
    fi

    cp -r ../ModelSEED $INSTALL/ModelSEED
fi
cd ..

echo "Finished!"

exit
