#!/bin/sh

# Start the continuous delivery process.

export OCD_ROOT=$(pwd)

source src/project_setup.sh
source src/update_remotes.sh
source src/build_octave.sh stable
source src/build_octave.sh default
