#!/bin/bash

# Clean existing environment
module --force purge

# Load common packages
module load ncarenv/24.12
module load gcc/12.4.0
module load ncarcompilers/1.0.0
module load cray-mpich/8.1.29
module load cmake/3.26.6
module load openblas/0.3.28
module load parallelio/2.6.3
module load esmf/8.9.0
module load netcdf-mpi/4.9.2
module load parallel-netcdf/1.14.0
module load hdf5-mpi/1.12.3

# Get FMS from UFS-WM spack-stack installation
module use -a /glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.9.3/envs/ue-gcc-12.4.0/install/modulefiles/gcc/12.4.0
module use -a /glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.9.3/envs/ue-gcc-12.4.0/install/modulefiles/cray-mpich/8.1.29-amzxfjj/gcc/12.4.0
module load fms/2024.02

# List loaded packages
module li

# Set required variables
export PIO_C_PATH=${PIO}
export PIO_Fortran_PATH=${PIO}
export PIO_C_LIBRARY=${PIO_C_PATH}/lib
export PIO_C_INCLUDE_DIR=${PIO_C_PATH}/include
export PIO_Fortran_LIBRARY=${PIO_Fortran_PATH}/lib
export PIO_Fortran_INCLUDE_DIR=${PIO_Fortran_PATH}/include
export FMS_ROOT=$fms_ROOT

