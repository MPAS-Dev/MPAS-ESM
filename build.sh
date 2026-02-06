#!/bin/bash

# Load environment
source envs/derecho_env_gnu.sh

# Clean old build
rm -rf build install esmxBuild.yaml

# Create esmxBuild.yaml
echo "application:" >> esmxBuild.yaml
echo "  disable_comps: ESMX_Data" >> esmxBuild.yaml
echo "  link_libraries: piof" >> esmxBuild.yaml
echo "components:" >> esmxBuild.yaml
echo "  mpas_atm_nuopc:" >> esmxBuild.yaml
echo "    source_dir: src/MPAS-Model" >> esmxBuild.yaml
echo "    build_type: cmake.external" >> esmxBuild.yaml
echo "    build_args: \"-DMPAS_NUOPC=ON -DMPAS_DOUBLE_PRECISION=OFF -DMPAS_USE_PIO=ON\"" >> esmxBuild.yaml

# Build application
ESMX_Builder -v --build-jobs=4
