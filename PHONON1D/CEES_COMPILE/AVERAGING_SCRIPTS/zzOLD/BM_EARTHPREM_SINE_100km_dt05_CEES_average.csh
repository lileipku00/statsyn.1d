#!/bin/csh

average_output << EOF
./LISTS/BM_EARTHPREM_SINE_100km_dt05_CEES.0100.20.lpr.list
./AVERAGED_OUTPUTS/BM_EARTHPREM_SINE_100km_dt05_CEES.0100.20.lpr
0.0500
EOF

average_output << EOF
./LISTS/BM_EARTHPREM_SINE_100km_dt05_CEES.0100.20.lpz.list
./AVERAGED_OUTPUTS/BM_EARTHPREM_SINE_100km_dt05_CEES.0100.20.lpz
0.0500
EOF

average_output << EOF
./LISTS/BM_EARTHPREM_SINE_100km_dt05_CEES.0100.20.lpt.list
./AVERAGED_OUTPUTS/BM_EARTHPREM_SINE_100km_dt05_CEES.0100.20.lpt
0.0500
EOF

