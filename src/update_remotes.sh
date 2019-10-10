#!/bin/sh

# Ensure all remote repositories are up to date.

cd $OCD_REMOTES_DIR/octave
hg pull

cd $OCD_REMOTES_DIR/mxe-octave
hg pull

cd $OCD_ROOT
