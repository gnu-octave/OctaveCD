#!/bin/sh

# Build a clean version of the given branch.

if [ $# -eq 0 ]; then
  echo "ERROR (build_octave.sh): No branch given."
  exit -1
fi

BRANCH=$1

#
# create a fresh local clone
#

cd $OCD_BUILD_DIR
hg clone $OCD_REMOTES_DIR/octave $BRANCH
cd $OCD_BUILD_DIR/${BRANCH}
hg update $BRANCH

#
# identify the HD ID
#

HG_ID=$(hg identify --id)
OCT_VER=$(grep -e "^AC_INIT" configure.ac | grep -Po "(\d+\.)+\d+")

# save HG_ID and Octave version globally
if [[ $BRANCH == "stable" ]];
then
  export OCD_STABLE_HG_ID=$HG_ID
  export OCD_STABLE_OCT_VER=$OCT_VER
elif [[ $BRANCH == "default" ]];
then
  export OCD_DEFAULT_HG_ID=$HG_ID
  export OCD_DEFAULT_OCT_VER=$OCT_VER
else
  echo "ERROR (build_octave.sh): Bad branch name \"${BRANCH}\" given."
  exit -1
fi

BUILD_DIR=$OCD_BUILD_DIR/${BRANCH}_${HG_ID}
EXPORT_DIR=$OCD_EXPORTS_DIR/${BRANCH}_${HG_ID}
LOG_FILE=$BUILD_DIR/build.log.html

#
# build the branch
#

if [ -d "$BUILD_DIR" ]; then
  echo "Do not build Octave ${BRANCH} again."
  rm -Rf $OCD_BUILD_DIR/${BRANCH}
else
  TIME_START=$(date --utc +"%F %H-%M-%S (UTC)")
  REPO_URL=https://hg.savannah.gnu.org/hgweb/octave/rev

  mv $OCD_BUILD_DIR/${BRANCH} $BUILD_DIR

  cd $BUILD_DIR
  {
  printf "<!DOCTYPE html>\n<html>\n<body>\n"
  printf "<h1>Octave ${BRANCH}</h1>\n"
  printf "<ul>\n<li>HG_ID: "
  printf "<a href=\"${REPO_URL}/${HG_ID}\">${HG_ID}</a>"
  printf "</li>\n<li>Start: ${TIME_START}</li>\n</ul>\n"

  printf "<details><summary>bootstrap</summary>\n"
  printf "<pre>\n"
  ./bootstrap
  printf "</pre>\n</details>\n"

  printf "<details><summary>configure</summary>\n"
  printf "<pre>\n"
  ./configure
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
  mkdir -p $EXPORT_DIR

  cd $BUILD_DIR
  cp -t $EXPORT_DIR            \
    $LOG_FILE                  \
    octave-${OCT_VER}.tar.gz   \
    octave-${OCT_VER}.tar.lz   \
    octave-${OCT_VER}.tar.xz   \
    doc/doxygen.zip            \
    doc/interpreter/manual.zip \
    doc/interpreter/octave.pdf
  rm -f $OCD_MXE_PKG_DIR/octave-${OCT_VER}.tar.lz
  cp -t $OCD_MXE_PKG_DIR       \
    octave-${OCT_VER}.tar.lz
fi

cd $OCD_ROOT
