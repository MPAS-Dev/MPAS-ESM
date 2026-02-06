#!/bin/bash

module --force purge

module load ncarenv/24.12 gcc/12.4.0 ncarcompilers cray-mpich cmake openblas parallelio
module load esmf/8.9.0 netcdf-mpi/4.9.3 parallel-netcdf hdf5-mpi
module li
