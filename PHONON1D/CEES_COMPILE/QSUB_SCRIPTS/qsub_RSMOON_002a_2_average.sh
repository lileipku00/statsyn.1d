#!/bin/tcsh
#PBS -N COMPILE_RSMOON_002a_2
#PBS -lmem=12gb,nodes=1:ppn=1
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh ./AVERAGING_SCRIPTS/RSMOON_002a_2_average.csh
