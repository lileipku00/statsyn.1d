#!/bin/tcsh
#PBS -N VPREM_nVL_001B_07Hz.csh
#PBS -l nodes=1:ppn=16
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh SCRIPTS_CEES/VPREM_nVL_001B_07Hz.csh.csh
