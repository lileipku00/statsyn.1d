#!/bin/tcsh


qsub CEES_QSUB_SCRIPTS/qsub_CSIMPLEMOON_Q2000_FirstS.sh
sleep 1
qsub CEES_QSUB_SCRIPTS/qsub_CSIMPLEMOON_Q6500_FirstS.sh
sleep 1
qsub CEES_QSUB_SCRIPTS/qsub_CSIMPLEMOON_basic_FirstS.sh
sleep 1
qsub CEES_QSUB_SCRIPTS/qsub_CSIMPLEMOON_basic_dQ2_FirstS.sh
sleep 1
qsub CEES_QSUB_SCRIPTS/qsub_CSIMPLEMOON_crust_FirstS.sh
sleep 1
