#!/bin/sh

# Exit when any command fails.
set -e

# Build a clean version of the given branch.

if [ $# -eq 0 ];
then
  echo "ERROR (build_octave.sh): No changeset given."
  exit -1
fi

CHANGESET=$1

#
# Create a fresh local clone.
#

cd $OCD_BUILD_DIR
hg clone $OCD_REMOTES_DIR/octave $CHANGESET
cd $OCD_BUILD_DIR/${CHANGESET}

#
# Update fresh local clone to changeset.  If invalid the script will fail here.
#

hg update $CHANGESET

#
# Identify the HD ID.
#

HG_ID=$(hg identify --id)
OCT_VER=$(grep -e "^AC_INIT" configure.ac | grep -Po "(\d+\.)+\d+")

#
# Save HG_ID and Octave version globally.
#

if [[ $CHANGESET == "stable" ]];
then
  export OCD_STABLE_HG_ID=$HG_ID
  export OCD_STABLE_OCT_VER=$OCT_VER
  BUILD_DIR=$OCD_BUILD_DIR/${CHANGESET}_${HG_ID}
  EXPORT_DIR=$OCD_EXPORTS_DIR/${CHANGESET}_${HG_ID}
elif [[ $CHANGESET == "default" ]];
then
  export OCD_DEFAULT_HG_ID=$HG_ID
  export OCD_DEFAULT_OCT_VER=$OCT_VER
  BUILD_DIR=$OCD_BUILD_DIR/${CHANGESET}_${HG_ID}
  EXPORT_DIR=$OCD_EXPORTS_DIR/${CHANGESET}_${HG_ID}
else
  BUILD_DIR=$OCD_BUILD_DIR/${OCT_VER}
  EXPORT_DIR=$OCD_EXPORTS_DIR/${OCT_VER}
fi

LOG_FILE=$BUILD_DIR/build.log.html

#
# build the branch
#

if [ -d "$BUILD_DIR" ];
then
  echo "  --> Do not build Octave ${CHANGESET} again."
  rm -Rf $OCD_BUILD_DIR/${CHANGESET}
else
  TIME_START=$(date --utc +"%F %H-%M-%S (UTC)")
  REPO_URL=https://hg.savannah.gnu.org/hgweb/octave/rev

  mv $OCD_BUILD_DIR/${CHANGESET} $BUILD_DIR

  cd $BUILD_DIR
  {
  printf "<!DOCTYPE html>\n<html>\n<body>\n"
  printf "<h1>Octave ${CHANGESET}</h1>\n"
  printf "<ul>\n<li>HG_ID: "
  printf "<a href=\"${REPO_URL}/${HG_ID}\">${HG_ID}</a>"
  printf "</li>\n<li>Start: ${TIME_START}</li>\n</ul>\n"

  printf "<details><summary>bootstrap</summary>\n"
  printf "<pre>\n"
  ./bootstrap --gnulib-srcdir=${OCD_GNULIB_DIR}
  printf "</pre>\n</details>\n"

  printf "<details><summary>configure</summary>\n"
  printf "<pre>\n"
  ./configure
  printf "</pre>\n</details>\n"

  printf "<details><summary>make</summary>\n"
  printf "<pre>\n"
  # https://savannah.gnu.org/bugs/?56952
  until make -j4; do
    echo "make invocation."
  done
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

if [ -d "$EXPORT_DIR" ];
then
  echo "  --> Do not export Octave ${CHANGESET} again."
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
  if [[ $CHANGESET == "stable" ]] || [[ $CHANGESET == "default" ]];
  then
    rm -f $OCD_MXE_PKG_DIR/octave-${OCT_VER}.tar.lz
    cp -t $OCD_MXE_PKG_DIR octave-${OCT_VER}.tar.lz
  fi
fi

cd $OCD_ROOT
