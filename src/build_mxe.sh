#!/bin/sh

# Build a clean version of the given branch.

if [ $# -lt 2 ]; then
  echo "ERROR (build_mxe.sh): Need to provide branch and MXE configuration."
  exit -1
fi

BRANCH=$1
MXE_CONFIG=$2

#
# update the branch
#

cd $OCD_REPO_DIR/mxe
hg pull
hg update --clean
hg purge

#
# Update to tag/revision or stay at top of branch
#

if [ $# -eq 3 ]; then
  hg update $3
fi

if [[ $BRANCH == "stable" ]] || [[ $BRANCH == "release" ]];
then
  HG_ID=$OCD_STABLE_HG_ID
elif [[ $BRANCH == "default" ]];
then
  HG_ID=$OCD_DEFAULT_HG_ID
else
  echo "ERROR (build_mxe.sh): Bad branch name \"${BRANCH}\" given."
  exit -1
fi

read -d '' MXE_CONFIG_OPTS << EOF
--enable-devel-tools              \
--enable-binary-packages          \
--with-ccache                     \
--with-pkg-dir=${OCD_MXE_PKG_DIR} \
--enable-octave=${BRANCH}
EOF

if [[ ${MXE_CONFIG} == "w64" ]];
then
  MXE_CONFIG_OPTS=${MXE_CONFIG_OPTS}
elif [[ ${MXE_CONFIG} == "w64-64" ]];
then
  MXE_CONFIG_OPTS="${MXE_CONFIG_OPTS} --enable-fortran-int64"
elif [[ ${MXE_CONFIG} == "w32" ]];
then
  MXE_CONFIG_OPTS="${MXE_CONFIG_OPTS} --disable-windows-64"
else
  echo "ERROR (build_mxe.sh): Bad MXE configuration \"${MXE_CONFIG}\" given."
  exit -1
fi

if [[ $BRANCH == "release" ]];
then
  BUILD_DIR=/release/mxe_${MXE_CONFIG}
else
  BUILD_DIR=$OCD_BUILD_DIR/mxe_${BRANCH}_${MXE_CONFIG}
fi
EXPORT_DIR=$OCD_EXPORTS_DIR/${BRANCH}_${HG_ID}
LOG_FILE=$BUILD_DIR/build_mxe_${MXE_CONFIG}.log.html

#
# build the branch
#

TIME_START=$(date --utc +"%F %H-%M-%S (UTC)")
REPO_URL=https://hg.savannah.gnu.org/hgweb/octave/rev

mkdir -p $BUILD_DIR

cd $BUILD_DIR
{
printf "<!DOCTYPE html>\n<html>\n<body>\n"
printf "<h1>Octave ${BRANCH} MXE (${MXE_CONFIG})</h1>\n"
printf "<ul>\n<li>HG_ID: "
printf "<a href=\"${REPO_URL}/${HG_ID}\">${HG_ID}</a>"
printf "</li>\n<li>Start: ${TIME_START}</li>\n</ul>\n"

printf "<details><summary>configure</summary>\n"
printf "<pre>\n"
${OCD_REPO_DIR}/mxe/configure ${MXE_CONFIG_OPTS}
printf "</pre>\n</details>\n"

printf "<details><summary>make</summary>\n"
printf "<pre>\n"
$MAKE JOBS=4 all nsis-installer 7z-dist zip-dist
printf "</pre>\n</details>\n"

TIME_END=$(date --utc +"%F %H-%M-%S (UTC)")
printf "<ul>\n<li>End: ${TIME_END}</li>\n</ul>\n"

printf "</body>\n</html>\n"
} 2>&1 | tee $LOG_FILE


#
# export relevant artifacts
#

mkdir -p $EXPORT_DIR

cd $BUILD_DIR/dist
cp -t $EXPORT_DIR  \
  $LOG_FILE        \
  octave-*.exe     \
  octave-*.7z      \
  octave-*.zip

cd $OCD_ROOT
