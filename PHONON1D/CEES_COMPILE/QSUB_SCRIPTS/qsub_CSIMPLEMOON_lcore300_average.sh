#!/bin/tcsh
#PBS -N COMPILE_CSIMPLEMOON_lcore300
#PBS -lmem=12gb,nodes=1:ppn=1
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh ./AVERAGING_SCRIPTS/CSIMPLEMOON_lcore300_average.csh
