#!/bin/tcsh
#PBS -N BM_EARTHPREM_SPIKE_100km_dt05_CEES_C
#PBS -l nodes=1:ppn=16
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh SCRIPTS_CEES/BM_EARTHPREM_SPIKE_100km_dt05_CEES_C.csh
