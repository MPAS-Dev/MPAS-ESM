#!/bin/bash

# Clean existing environment
module --force purge

# Load common packages
module use /glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/Core
module use /glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/cray-mpich/8.1.29-3sepg3g/gcc/12.4.0
module load stack-oneapi/2024.2.1
module load stack-cray-mpich/8.1.29
module load cmake/3.27.9
module load hdf5/1.14.3
module load netcdf-c/4.9.2
module load netcdf-fortran/4.6.1
module load parallelio/2.6.2
module load esmf/8.8.0
module load fms/2024.02

# List loaded packages
module li

# Update esmf.mk file since ESMF_F90LINKOPTS has -cxxlib 
cp -rf $ESMFMKFILE $PWD/esmf.mk.patched
sed -i 's/ -cxxlib / /g' $PWD/esmf.mk.patched
sed -i 's/ -threads / /g' $PWD/esmf.mk.patched
export ESMFMKFILE=$PWD/esmf.mk.patched

# Set required variables
export CC="mpicc"
export CXX="mpicxx"
export FC="mpif90"
export I_MPI_CC="icx"
export I_MPI_CXX="icpx"
export I_MPI_F90="ifort"
export PIO=${parallelio_ROOT}
export PIO_C_PATH=${PIO}
export PIO_Fortran_PATH=${PIO}
export PIO_C_LIBRARY=${PIO_C_PATH}/lib
export PIO_C_INCLUDE_DIR=${PIO_C_PATH}/include
export PIO_Fortran_LIBRARY=${PIO_Fortran_PATH}/lib
export PIO_Fortran_INCLUDE_DIR=${PIO_Fortran_PATH}/include
export FMS_ROOT=$fms_ROOT
