#!/bin/tcsh
#PBS -N VPREM_008_40Hz
#PBS -l nodes=1:ppn=16
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh SCRIPTS_CEES/VPREM_008_40Hz.csh