#!/bin/tcsh
#PBS -N COMPILE_VSMOON_001b
#PBS -lmem=12gb,nodes=1:ppn=1
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh ./AVERAGING_SCRIPTS/VSMOON_001b_average.csh
