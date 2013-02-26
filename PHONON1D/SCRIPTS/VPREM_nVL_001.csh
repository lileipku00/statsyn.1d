#!/bin/csh

#
# Set synthetic parameters
#


set ray_par    = "0.0 0.1668 0.2931"
@ t_start      = 0
@ t_max        = 5400			# 75 minutes
set d_range    = "0 180 91"
set model      = "2"	#2 for Moon
set mx_scat_dp = "10"
set n_phonon   = "10000000"


# SCATTERING
set bg_scat    = 0.001
set prob_scat  = 0.5
set dsmin      = 0.05   # Min scaterrer length scale
set dsmax      = 10     # Max scaterrer length scale
set npow       = -0.5   # Power law factor for scatterer lengthscale
set velperturb = 0.6

# Source attenuation and type
set dQdfstyle  = 1
set sourcetype = "2"    #(2 is sine)


set file_out   = "VPREM_nVL_001"
set model_name = "VPREMOON_Qp_novlvl_10km"

@ n_depth = 3     ## Number of depths to use
@ n_freq  = 2     ## Number of frequency bands (40s and 6.66666s)
@ n_kern  = 6     ## Number of kernels to use per iteration (simultaneous run)
@ n_iter  = 4    ## Number of iterations

# Output folder
set out_dir    = "./OUTPUT"
set outTRACK_dir    = "./TRACKING"
set log_dir    = "./LOG"


# Compile statistical phonon code
cd SRC
make statsyn_VPREM.x
cd ..


##
# Loop over FREQUENCY
##
@ l = 0
while ($l < $n_freq)
@ l = $l + 1

if ($l == 2) then
 set dt = "0.025"
 set period = "40"
else
 set dt = "0.150"
 set period = "07"
endif


##
# Loop over DEPTH
##
@ i  =  0
while ($i < $n_depth)
@ i = $i + 1
if ($i == 2) then
 set q_depth = 20
else if ($i == 1) then
 set q_depth = 1100
else
 set q_depth = 0.01
endif

echo "Depth=:" $q_depth

##
# Loop over ITERATIONS
##
@ k  = 0
while ($k < $n_iter)
@ k = $k + 1


##
# Loop over KERNELS
##
@ j  = 0
while ($j < $n_kern)
@ j = $j + 1


sleep 4

## 
# Start phonon synthetics
##

set file_whole = $file_out.$q_depth.$j.$k.$period
set file_log = log.$file_out.$q_depth.$j.$k.$period
set file_track = $file_out.$q_depth.$j.$k.$period.TRACK
set file_csh   = SCRIPTS_RUN/$file_out.$q_depth.$j.$k.$period.csh

echo "./bin/statsyn_VPREM << EOF"                              >  $file_csh
echo "./MODELS/$model_name"				>> $file_csh
# Next linei is obsolete but still needed because code hasn't been changed.
echo "$ray_par          \!LIMIT THE RAY PARAMETER"          >> $file_csh
echo "$t_start $t_max $dt \!LIMIT THE TIME WINDOW (SECONDS) " >> $file_csh
echo "$d_range          \!LIMIT THE DISTANCE (DEGREES)    " >> $file_csh
echo "$n_phonon         \!NUMBER OF PHONONS TO FIRE       " >> $file_csh
echo "$q_depth          \!DEPTH OF SOURCE                 " >> $file_csh
echo "$model            \!1=EARTH, 2=MOON                 " >> $file_csh
echo "$mx_scat_dp       \!MAX SCATTERING DEPTH            " >> $file_csh
echo "$prob_scat          \!SCATTERING PROB (SIMILAR TO RMS)" >> $file_csh
echo "$bg_scat          \!BACKGROUND SCATTERING PROB (SIMILAR TO RMS)" >> $file_csh
echo "$dsmin $dsmax $npow \!SCATERER SCALE-LENGTHS"          >> $file_csh
echo "$velperturb         \!VELOCITY PERTURBATION"          >> $file_csh
echo "$dQdfstyle        \!dQ/df Style            "          >> $file_csh
echo "$sourcetype        \!Source Type            "          >> $file_csh
echo "$outTRACK_dir/$file_track"                            >> $file_csh
echo "$out_dir/$file_whole"                                 >> $file_csh
echo "$log_dir/$file_log"                                 >> $file_csh
echo "EOF"                                                  >> $file_csh

echo " " >> $file_csh

#
if ($j == $n_kern)  then
csh $file_csh
endif
if ($j < $n_kern) then
csh $file_csh &
endif

#\rm OUTPUT/*.lpt

end
echo end inner loop for many kernels

end
echo end outer loop for many iterations.

end 
echo end depth loop.

end 
echo end loop over frequencies
