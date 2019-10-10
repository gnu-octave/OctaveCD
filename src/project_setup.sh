#!/bin/sh

# Ensure a basic setup of this continuous delivery project and exports some
# useful path variables.

if [ -z "$OCD_ROOT" ]; then
  echo "ERROR (project_setup.sh): OCD_ROOT is not set."
  exit 0
fi

export OCD_BUILD_DIR=$OCD_ROOT/build
export OCD_EXPORTS_DIR=$OCD_ROOT/exports

export OCD_REPO_DIR=$OCD_ROOT/repo
export OCD_REMOTES_DIR=$OCD_REPO_DIR/remotes
export OCD_PATCHES_DIR=$OCD_REPO_DIR/patches

#
# ensure paths exist
#

cd $OCD_ROOT
mkdir -p            \
  $OCD_BUILD_DIR    \
  $OCD_EXPORTS_DIR  \
  $OCD_REMOTES_DIR  \
  $OCD_PATCHES_DIR


#
# ensure repositories exist
#

if [ ! -d "$OCD_REMOTES_DIR/octave" ]; then
  cd $OCD_REMOTES_DIR
  hg clone https://www.octave.org/hg/octave
fi

if [ ! -d "$OCD_REMOTES_DIR/mxe-octave" ]; then
  cd $OCD_REMOTES_DIR
  hg clone https://hg.octave.org/mxe-octave
fi

if [ ! -d "$OCD_REPO_DIR/stable" ]; then
  cd $OCD_REPO_DIR
  hg clone $OCD_REMOTES_DIR/octave stable
fi

if [ ! -d "$OCD_REPO_DIR/default" ]; then
  cd $OCD_REPO_DIR
  hg clone $OCD_REMOTES_DIR/octave default
fi

if [ ! -d "$OCD_REPO_DIR/mxe" ]; then
  cd $OCD_REPO_DIR
  hg clone $OCD_REMOTES_DIR/mxe-octave mxe
fi

cd $OCD_ROOT