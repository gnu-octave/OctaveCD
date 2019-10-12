#!/bin/sh

# Build a clean version of the given branch.

if [ $# -eq 0 ]; then
  echo "ERROR (build_octave.sh): No branch given."
  exit 0
fi

BRANCH=$1

#
# update the branch
#

cd $OCD_REPO_DIR/$BRANCH
hg pull
hg update --clean $BRANCH
hg purge
./bootstrap

HG_ID=$(hg identify --id)

#
# build the branch
#

NOW=$(date +"%F_%H-%M-%S")
LOG_FILE=${BRANCH}_${HG_ID}_$NOW.log.html
BUILD_DIR=$OCD_BUILD_DIR/${BRANCH}_${HG_ID}
mkdir -p $BUILD_DIR

cd $BUILD_DIR
pwd
{
printf "<!DOCTYPE html>\n<html>\n<body>\n"
printf "<h1>Octave ${BRANCH} (HG_ID: "
printf "<a href=\"https://hg.savannah.gnu.org/hgweb/octave/rev/${HG_ID}\">${HG_ID}</a>"
printf ") $NOW</h1>\n"

printf "<details><summary>configure</summary>\n"
printf "<pre>\n"
$OCD_REPO_DIR/$BRANCH/configure
printf "</pre>\n</details>\n"

printf "<details><summary>make</summary>\n"
printf "<pre>\n"
make
printf "</pre>\n</details>\n"

printf "<details><summary>make check</summary>\n"
printf "<pre>\n"
make check
printf "</pre>\n</details>\n"

printf "<details><summary>make dist</summary>\n"
printf "<pre>\n"
make dist
printf "</pre>\n</details>\n"

printf "<details><summary>make doxyhtml</summary>\n"
printf "<pre>\n"
make doxyhtml
printf "</pre>\n</details>\n"

printf "</body>\n</html>\n"
} 2>&1 | tee $LOG_FILE

#
# export relevant artifacts
#

cd $BUILD_DIR/doc
zip -r doxygen.zip doxyhtml
cd $BUILD_DIR/doc/interpreter
zip -r manual.zip octave.html
cd $BUILD_DIR

EXPORT_DIR=$OCD_EXPORTS_DIR/${BRANCH}_${HG_ID}
mkdir -p $EXPORT_DIR

cp -t $EXPORT_DIR            \
  $LOG_FILE                  \
  octave-*.tar.*             \
  doc/doxygen.zip            \
  doc/interpreter/manual.zip \
  doc/interpreter/octave.pdf

cd $OCD_ROOT
