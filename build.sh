#!/bin/bash

# usage instructions
usage () {
cat << EOF_USAGE
Usage: $0 --platform=PLATFORM [OPTIONS] ... [TARGETS]

OPTIONS
  --build-jobs=BUILD_JOBS
      number of build jobs; defaults to 4
  --component-list=COMPONENT_LIST
      list of component/s to couple with MPAS seperated with comma
      (e.g. mom6 | docn )
  -c, --compiler=COMPILER
      compiler to use; default depends on platform
      (e.g. intel | gnu)
  -p, --platform=PLATFORM
      name of machine you are building on
      (e.g. derecho)
  --remove
      removes existing build
  -v, --verbose
      build with verbose output

NOTE: See User's Guide for detailed build instructions

EOF_USAGE
}

# print usage error and exit
usage_error () {
  printf "ERROR: $1\n" >&2
  usage >&2
  exit 1
}

# print settings
settings () {
cat << EOF_SETTINGS
Settings:

  BUILD_JOBS = ${BUILD_JOBS}
  COMPILER = ${COMPILER}
  COMPONENT_LIST = ${COMPONENT_LIST}
  PLATFORM = ${PLATFORM}
  REMOVE = ${REMOVE}
  VERBOSE = ${VERBOSE}

EOF_SETTINGS
}

# process required arguments
if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
  usage
  exit 0
fi

# default settings
APP_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
BUILD_DIR="${BUILD_DIR:-${APP_DIR}/build}"
BUILD_JOBS=4
COMPILER="gnu"
INSTALL_DIR=${INSTALL_DIR:-${APP_DIR}/install}
PLATFORM="derecho"
REMOVE=false
VERBOSE=true

# check arguments and set their values
while :; do
  case $1 in
    --build-jobs=?*) BUILD_JOBS=$((${1#*=})) ;;
    --build-jobs|--build-jobs=) usage_error "$1 requires argument." ;;
    --compiler=?*|-c=?*) COMPILER=${1#*=} ;;
    --compiler|--compiler=|-c|-c=) usage_error "$1 requires argument." ;;
    --component-list=?*) COMPONENT_LIST=${1#*=} ;;
    --component-list=) usage_error "$1 argument ignored." ;;
    --platform=?*|-p=?*) PLATFORM=${1#*=} ;;
    --platform|--platform=|-p|-p=) usage_error "$1 requires argument." ;;
    --remove) REMOVE=true ;;
    --remove=?*|--remove=) usage_error "$1 argument ignored." ;;
    --verbose|-v) VERBOSE=true ;;
    --verbose=?*|--verbose=) usage_error "$1 argument ignored." ;;
    # unknown
    -?*|?*) usage_error "Unknown option $1" ;;
    *) break
  esac
  shift
done

# ensure uppercase/lowercase
COMPILER=$(echo ${COMPILER} | tr '[A-Z]' '[a-z]')
COMPONENT_LIST=$(echo ${COMPONENT_LIST} | tr '[A-Z]' '[a-z]')
PLATFORM=$(echo ${PLATFORM} | tr '[A-Z]' '[a-z]')

# check requested components and create dictionary
declare -A dict_comps
dict_comps["mom6"]="false"
dict_comps["docn"]="false"
OLD_IFS="$IFS"
IFS=','
for key in $COMPONENT_LIST; do
  read -r key <<< "$key"
  if [[ -v dict_comps["$key"] ]]; then
    dict_comps["$key"]="true"
  else
    printf "\nERROR: Given component ($key) is not supported!\n\n"
    usage
    exit 0
  fi
done
IFS="$OLD_IFS"

# add CDEPS if MOM6 is requested
# MOM6 requires CDEPS shared code
if [[ "${dict_comps["mom6"]}" == "true" ]]; then
  COMPONENT_LIST="${COMPONENT_LIST},docn"
  dict_comps["docn"]="true"
fi

set -eu

# print settings
if [ "${VERBOSE}" = true ] ; then
  settings
fi

# Load environment
if [ -f "envs/${PLATFORM}_env_${COMPILER}.sh" ]; then
  source envs/${PLATFORM}_env_${COMPILER}.sh
else
  printf "\nERROR: ${PLATFORM} with ${COMPILER} compiler is not supported!\n\n"
  usage
  exit 0
fi

# Clean build
if [ "${REMOVE}" = true ]; then
  # Clean build and install directories
  if [ -d "${BUILD_DIR}" ]; then
    printf "Build directory already exists! Removing ${BUILD_DIR} ...\n"
    rm -rf ${BUILD_DIR}
  fi
  if [ -d "${INSTALL_DIR}" ]; then
    printf "Install directory already exists! Removing ${INSTALL_DIR} ...\n"
    rm -rf ${INSTALL_DIR}
  fi
else
  # Remove cache to prevent hanging
  rm -rf build/CMakeCache.txt build/CMakeFiles
fi

# Remove exiting esmxBuild.yaml
if [ -f "esmxBuild.yaml" ]; then
  rm -rf esmxBuild.yaml
fi

# Create esmxBuild.yaml
export FFLAGS="-DCPRGNU"
echo "application:" >> esmxBuild.yaml
echo "  disable_comps: ESMX_Data" >> esmxBuild.yaml
echo "  link_libraries: piof" >> esmxBuild.yaml
echo "components:" >> esmxBuild.yaml
# MPAS
echo "  mpas_atm_nuopc:" >> esmxBuild.yaml
echo "    source_dir: src/MPAS-Model" >> esmxBuild.yaml
echo "    build_type: cmake.external" >> esmxBuild.yaml
echo "    build_args: \"-DMPAS_NUOPC=ON -DMPAS_DOUBLE_PRECISION=OFF -DMPAS_USE_PIO=ON\"" >> esmxBuild.yaml
# DOCN
if [[ "${dict_comps["docn"]}" == "true" ]]; then
  echo "  docn:" >> esmxBuild.yaml
  echo "    source_dir: src/CDEPS" >> esmxBuild.yaml
  echo "    build_type: cmake.external" >> esmxBuild.yaml
  if [[ "${COMPILER}" == "gnu" ]]; then
    echo "    build_args: \"-DDISABLE_FoX=ON -DPIO_C_LIBRARY=$PIO_C_LIBRARY -DPIO_C_INCLUDE_DIR=$PIO_C_INCLUDE_DIR -DPIO_Fortran_LIBRARY=$PIO_Fortran_LIBRARY -DPIO_Fortran_INCLUDE_DIR=$PIO_Fortran_INCLUDE_DIR -DCMAKE_Fortran_FLAGS='-ffree-line-length-none'\"" >> esmxBuild.yaml
  else
    echo "    build_args: \"-DDISABLE_FoX=ON -DPIO_C_LIBRARY=$PIO_C_LIBRARY -DPIO_C_INCLUDE_DIR=$PIO_C_INCLUDE_DIR -DPIO_Fortran_LIBRARY=$PIO_Fortran_LIBRARY -DPIO_Fortran_INCLUDE_DIR=$PIO_Fortran_INCLUDE_DIR\"" >> esmxBuild.yaml
  fi
  echo "    fort_module: cdeps_docn_comp.mod" >> esmxBuild.yaml
  echo "    libraries: docn dshr streams cdeps_share" >> esmxBuild.yaml
fi
# MOM6
if [[ "${dict_comps["mom6"]}" == "true" ]]; then
  echo "  mom6:" >> esmxBuild.yaml
  echo "    source_dir: src/MOM6_interface" >> esmxBuild.yaml
  echo "    build_type: cmake.external" >> esmxBuild.yaml
  echo "    fort_module: mom_cap_mod" >> esmxBuild.yaml
  echo "    libraries: mom6" >> esmxBuild.yaml
  echo "    link_paths: $FMS_ROOT" >> esmxBuild.yaml
  echo "    link_libraries: fms_r8 cdeps_share" >> esmxBuild.yaml
fi

# Build application
ESMX_Builder -v --build-jobs=${BUILD_JOBS} --cmake-args="-DCMAKE_Fortran_FLAGS=-I${PWD}/install/mod"
