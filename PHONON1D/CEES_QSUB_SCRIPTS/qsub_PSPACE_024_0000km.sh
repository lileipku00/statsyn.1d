#!/bin/tcsh
#PBS -N PSPACE_024_0000km
#PBS -l nodes=1:ppn=16
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh SCRIPTS_CEES/PSPACE_024_0000km.csh
