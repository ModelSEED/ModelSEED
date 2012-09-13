#!/bin/sh

# script to build a ModelSEED dist from source

VER=$1
if [ -z $VER ]; then
    echo "Please enter a version number (e.g. 0.50)"
    exit 2
fi

while true; do
    read -p "Have you changed the version in lib/ModelSEED/Version.pm to match '$VER'? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* )
            exit
            ;;
        * ) echo "Please answer yes or no.";;
    esac
done

# create a temp dir (you'd think there would be a POSIX compliant way to do this)
RAND=$( printf '%x' $( ( echo $$ ; time ps ; w ; date ) 2>&1 | cksum | cut -f1 -d " " ) )

TMPDIR=/tmp/$RAND
ORIGDIR="$( pwd )"
DIR="$( cd "$( dirname "$0" )" && pwd )"

mkdir -p $TMPDIR/ModelSEED

echo "Copying ModelSEED files to temp directory..."
cp -r $DIR/../* $TMPDIR/ModelSEED

cd $TMPDIR/ModelSEED
echo "Removing unnecessary files..."
if [ -f "Build" ]; then
    ./Build realclean 1>/dev/null 2>&1
fi

if [ -f ".gitignore" ]; then
    rm .gitignore
fi

if [ -d ".git" ]; then
    rm -rf .git
fi

echo "Creating tarball archive..."
cd ..
tar -czf $ORIGDIR/ModelSEED_v$VER.tgz ModelSEED

echo "Finished! Created file 'ModelSEED_v$VER.tgz'"
