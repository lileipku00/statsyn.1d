#!/bin/tcsh
#PBS -N COMPILE_FSMOON_011a
#PBS -lmem=12gb,nodes=1:ppn=1
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh ./AVERAGING_SCRIPTS/FSMOON_011a_average.csh
