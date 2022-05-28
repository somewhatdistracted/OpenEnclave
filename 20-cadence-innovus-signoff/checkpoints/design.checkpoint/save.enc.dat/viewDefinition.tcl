if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name libs_typical\
   -timing\
    [list ${::IMEX::libVar}/mmmc/stdcells.lib\
    ${::IMEX::libVar}/mmmc/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib]
create_rc_corner -name typical\
   -cap_table ${::IMEX::libVar}/mmmc/rtk-typical.captable\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -T 25
create_delay_corner -name delay_default\
   -rc_corner typical\
   -early_library_set libs_typical\
   -late_library_set libs_typical
create_constraint_mode -name constraints_default\
   -sdc_files\
    [list /dev/null]
create_analysis_view -name analysis_default -constraint_mode constraints_default -delay_corner delay_default -latency_file /home/users/ianpmac/EE372-Project/skywater-digital-flow/HEModules/build/16-cadence-innovus-cts/checkpoints/design.checkpoint/save.enc.dat/libs/mmmc/latency.sdc
set_analysis_view -setup [list analysis_default] -hold [list analysis_default]
