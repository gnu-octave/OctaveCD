#!/bin/sh

# Build a clean version of the given branch.

if [ $# -eq 0 ]; then
  echo "ERROR (build_octave.sh): No branch given."
  exit -1
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
OCT_VER=$(grep -e "^AC_INIT" configure.ac | grep -e "[0-9]\.[0-9]\.[0-9]" -o)

BUILD_DIR=$OCD_BUILD_DIR/${BRANCH}_${HG_ID}
EXPORT_DIR=$OCD_EXPORTS_DIR/${BRANCH}_${HG_ID}
LOG_FILE=$BUILD_DIR/build.log.html

#
# build the branch
#

if [ -d "$BUILD_DIR" ]; then
  echo "Do not build Octave ${BRANCH} again."
else
  TIME_START=$(date --utc +"%F %H-%M-%S (UTC)")
  REPO_URL=https://hg.savannah.gnu.org/hgweb/octave/rev

  mkdir -p $BUILD_DIR

  cd $BUILD_DIR
  pwd
  {
  printf "<!DOCTYPE html>\n<html>\n<body>\n"
  printf "<h1>Octave ${BRANCH}</h1>\n"
  printf "<ul>\n<li>HG_ID: "
  printf "<a href=\"${REPO_URL}/${HG_ID}\">${HG_ID}</a>"
  printf "</li>\n<li>Start: ${TIME_START}</li>\n</ul>\n"

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

  TIME_END=$(date --utc +"%F %H-%M-%S (UTC)")
  printf "<ul>\n<li>End: ${TIME_END}</li>\n</ul>\n"

  printf "</body>\n</html>\n"
  } 2>&1 | tee $LOG_FILE

  # compress documentation files
  cd $BUILD_DIR/doc
  zip -r doxygen.zip doxyhtml
  cd $BUILD_DIR/doc/interpreter
  zip -r manual.zip octave.html
fi


#
# export relevant artifacts
#

if [ -d "$EXPORT_DIR" ]; then
  echo "Do not export Octave ${BRANCH} again."
else
  TIME_START=$(date --utc +"%F %H-%M-%S (UTC)")
  REPO_URL=https://hg.savannah.gnu.org/hgweb/octave/rev

  mkdir -p $EXPORT_DIR

  cd $BUILD_DIR
  cp -t $EXPORT_DIR            \
    $LOG_FILE                  \
    octave-*.tar.*             \
    doc/doxygen.zip            \
    doc/interpreter/manual.zip \
    doc/interpreter/octave.pdf
  printf "${HG_ID}\n${OCT_VER}" > $EXPORT_DIR/meta.txt
fi

cd $OCD_ROOT
