#!/bin/tcsh


qsub CEES_QSUB_SCRIPTS/qsub_PBASIN_2301_0000km_5Hz.sh
sleep 1
qsub CEES_QSUB_SCRIPTS/qsub_PBASIN_2301_1000km_5Hz.sh
sleep 1
qsub CEES_QSUB_SCRIPTS/qsub_PBASIN_2302_0000km_5Hz.sh
sleep 1
qsub CEES_QSUB_SCRIPTS/qsub_PBASIN_2302_1000km_5Hz.sh
sleep 1
