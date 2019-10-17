#!/bin/sh

# Start the continuous delivery process.

export OCD_ROOT=$(pwd)

source src/project_setup.sh
source src/update_remotes.sh
source src/build_octave.sh stable
source src/build_mxe.sh    stable w64
source src/build_mxe.sh    stable w64-64
source src/build_mxe.sh    stable w32
source src/build_octave.sh default
source src/build_mxe.sh    default w64
source src/build_mxe.sh    default w64-64
source src/build_mxe.sh    default w32
