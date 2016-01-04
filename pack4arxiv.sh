#!/usr/bin/env bash
#
# pack4arxiv by Andrew Pontzen
#
# Type pack4arxiv mypaper.tex to create a .tar.gz which is ready to upload
# to arxiv. This script gathers
#   - a copy of your .tex with any comments stripped out
#   - all referenced graphics files
#   - your .bbl file
#   - all .sty and .cls files in the same folder

pushdq () {
    pushd "$@" > /dev/null
}

popdq () {
    popd "$@" > /dev/null
}

if [ "$#" -lt 1 ]
then
    echo "Syntax: $0 <manuscript.tex> [<output.tar.gz>]"
    exit -1
fi

if [ ! -e $1 ]
then
    echo "Syntax: $0 <manuscript.tex> [<output.tar.gz>]"
    exit -1
fi

sourcedir=`dirname $1`
pushdq $sourcedir
sourcedir=`pwd`
popdq

if [ "$#" -gt 1 ]
then
    outputtar=`pwd`/$2
else
    outputtar=$sourcedir/submit.tar.gz
fi

if [ -e $outputtar ]
then
    echo "$outputtar already exists; aborting"
    exit -1
fi

tempdir=`mktemp -d`

echo "Stripping out comments..."
perl -pe '/^[^%]*[^\\]%%/ && next; s/([^\\]|^)%.*\n/\1% comment removed\n/g' $1 > $tempdir/$1


graphics=`perl -pe 's/(?<!^)(?=\\\\include)/\\n/g' $1 | sed -n 's/\\\\includegraphics\\[.*\\]{\\([^}]*\\)}/\\1/pg'`
echo $graphics
echo "Copying graphics..."
pushdq $sourcedir
for g in $graphics
do
  if [ -e $g ]
  then
    echo "  " $g
    cp $g $tempdir/
  fi
done

echo "Copying .sty, .cls..."

for f in *.sty *.cls
do
  if [ -e $f ]
  then
    echo "  " $f
    cp $f $tempdir/
  fi
done

popdq

echo "Copying .bbl..."

bbl=`echo $1 |  sed 's/\.tex/.bbl/g'`

if [ -e $bbl ]
then
    echo "  " $bbl
    cp $bbl $tempdir/
fi

pushdq $tempdir
echo "Generating $outputtar"
tar -czf $outputtar *
popdq

rm -rf $tempdir
