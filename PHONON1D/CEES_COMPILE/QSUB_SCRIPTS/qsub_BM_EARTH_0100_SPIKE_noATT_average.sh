#!/bin/tcsh
#PBS -N COMPILE_BM_EARTH_0100_SPIKE_noATT
#PBS -lmem=12gb,nodes=1:ppn=1
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh ./AVERAGING_SCRIPTS/BM_EARTH_0100_SPIKE_noATT_average.csh
