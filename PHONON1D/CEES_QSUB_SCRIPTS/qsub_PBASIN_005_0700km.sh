#!/bin/tcsh
#PBS -N PBASIN_005_0700km
#PBS -l nodes=1:ppn=16
#PBS -q jfl
#PBS -V
cd $PBS_O_WORKDIR

csh SCRIPTS_BASIN/PBASIN_005_0700km.csh
