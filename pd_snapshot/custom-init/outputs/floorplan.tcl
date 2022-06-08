#=========================================================================
# floorplan.tcl
#=========================================================================
# This script is called from the Innovus init flow step.
#
# Author : Christopher Torng
# Date   : March 26, 2018

#-------------------------------------------------------------------------
# Floorplan variables
#-------------------------------------------------------------------------

# Make room in the floorplan for the core power ring
set pwr_net_list {VDD VSS}; # List of power nets in the core power ring

set M1_min_width   [dbGet [dbGetLayerByZ 1].minWidth]
set M1_min_spacing [dbGet [dbGetLayerByZ 1].minSpacing]

set savedvars(p_ring_width)   [expr 48 * $M1_min_width];   # Arbitrary!
set savedvars(p_ring_spacing) [expr 24 * $M1_min_spacing]; # Arbitrary!

# Core bounding box margins
set core_margin_t [expr ([llength $pwr_net_list] * ($savedvars(p_ring_width) + $savedvars(p_ring_spacing))) + $savedvars(p_ring_spacing)]
set core_margin_b [expr ([llength $pwr_net_list] * ($savedvars(p_ring_width) + $savedvars(p_ring_spacing))) + $savedvars(p_ring_spacing)]
set core_margin_r [expr ([llength $pwr_net_list] * ($savedvars(p_ring_width) + $savedvars(p_ring_spacing))) + $savedvars(p_ring_spacing)]
set core_margin_l [expr ([llength $pwr_net_list] * ($savedvars(p_ring_width) + $savedvars(p_ring_spacing))) + $savedvars(p_ring_spacing)]

# User project area is limited to 2920um x 3520um
floorPlan -d [expr 2860] \
             [expr 3470] \
             $core_margin_l $core_margin_b $core_margin_r $core_margin_t


setFlipping s

# Macro 1
placeInstance sram_inst/width_macro1_0__depth_macro1_0__sram1 290 80
addHaloToBlock 8 8 8 8 sram_inst/width_macro1_0__depth_macro1_0__sram1
placeInstance sram_inst/width_macro1_1__depth_macro1_0__sram1 915 80
addHaloToBlock 8 8 8 8 sram_inst/width_macro1_1__depth_macro1_0__sram1
placeInstance sram_inst/width_macro1_2__depth_macro1_0__sram1 1540 80
addHaloToBlock 8 8 8 8 sram_inst/width_macro1_2__depth_macro1_0__sram1
placeInstance sram_inst/width_macro1_3__depth_macro1_0__sram1 2170 80
addHaloToBlock 8 8 8 8 sram_inst/width_macro1_3__depth_macro1_0__sram1

# Macro 2
placeInstance sram_inst/width_macro2_0__depth_macro2_0__sram2 290 580
addHaloToBlock 8 8 8 8 sram_inst/width_macro2_0__depth_macro2_0__sram2
placeInstance sram_inst/width_macro2_1__depth_macro2_0__sram2 915 580
addHaloToBlock 8 8 8 8 sram_inst/width_macro2_1__depth_macro2_0__sram2
placeInstance sram_inst/width_macro2_2__depth_macro2_0__sram2 1540 580
addHaloToBlock 8 8 8 8 sram_inst/width_macro2_2__depth_macro2_0__sram2
placeInstance sram_inst/width_macro2_3__depth_macro2_0__sram2 2170 580
addHaloToBlock 8 8 8 8 sram_inst/width_macro2_3__depth_macro2_0__sram2

# Macro 3
placeInstance sram_inst/width_macro3_0__depth_macro3_0__sram3 290 2140 
addHaloToBlock 8 8 8 8 sram_inst/width_macro3_0__depth_macro3_0__sram3
placeInstance sram_inst/width_macro3_1__depth_macro3_0__sram3 915 2140 
addHaloToBlock 8 8 8 8 sram_inst/width_macro3_1__depth_macro3_0__sram3
placeInstance sram_inst/width_macro3_2__depth_macro3_0__sram3 1540 2140 
addHaloToBlock 8 8 8 8 sram_inst/width_macro3_2__depth_macro3_0__sram3
placeInstance sram_inst/width_macro3_3__depth_macro3_0__sram3 2170 2140 
addHaloToBlock 8 8 8 8 sram_inst/width_macro3_3__depth_macro3_0__sram3

createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro1_0__depth_macro1_0__sram1
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro1_1__depth_macro1_0__sram1
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro1_2__depth_macro1_0__sram1
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro1_3__depth_macro1_0__sram1
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro2_0__depth_macro2_0__sram2
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro2_1__depth_macro2_0__sram2
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro2_2__depth_macro2_0__sram2
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro2_3__depth_macro2_0__sram2
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro3_0__depth_macro3_0__sram3
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro3_1__depth_macro3_0__sram3
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro3_2__depth_macro3_0__sram3
createRouteBlk -layer {li1} -cover -inst sram_inst/width_macro3_3__depth_macro3_0__sram3

# Macro 1
#placeInstance sram_inst/width_macro1_0__depth_macro1_0__sram1 290 140
#addHaloToBlock 8 8 8 8 sram_inst/width_macro1_0__depth_macro1_0__sram1
#placeInstance sram_inst/width_macro1_1__depth_macro1_0__sram1 290 640
#addHaloToBlock 8 8 8 8 sram_inst/width_macro1_1__depth_macro1_0__sram1
#placeInstance sram_inst/width_macro1_2__depth_macro1_0__sram1 290 1140
#addHaloToBlock 8 8 8 8 sram_inst/width_macro1_2__depth_macro1_0__sram1
#placeInstance sram_inst/width_macro1_3__depth_macro1_0__sram1 290 1640
#addHaloToBlock 8 8 8 8 sram_inst/width_macro1_3__depth_macro1_0__sram1

# Macro 2
#placeInstance sram_inst/width_macro2_0__depth_macro2_0__sram2 900 140
#addHaloToBlock 8 8 8 8 sram_inst/width_macro2_0__depth_macro2_0__sram2
#placeInstance sram_inst/width_macro2_1__depth_macro2_0__sram2 900 640
#addHaloToBlock 8 8 8 8 sram_inst/width_macro2_1__depth_macro2_0__sram2
#placeInstance sram_inst/width_macro2_2__depth_macro2_0__sram2 900 1140
#addHaloToBlock 8 8 8 8 sram_inst/width_macro2_2__depth_macro2_0__sram2
#placeInstance sram_inst/width_macro2_3__depth_macro2_0__sram2 900 1640
#addHaloToBlock 8 8 8 8 sram_inst/width_macro2_3__depth_macro2_0__sram2

# Macro 3
#placeInstance sram_inst/width_macro3_0__depth_macro3_0__sram3 2180 140 
#addHaloToBlock 8 8 8 8 sram_inst/width_macro3_0__depth_macro3_0__sram3
#placeInstance sram_inst/width_macro3_1__depth_macro3_0__sram3 2180 640 
#addHaloToBlock 8 8 8 8 sram_inst/width_macro3_1__depth_macro3_0__sram3
#placeInstance sram_inst/width_macro3_2__depth_macro3_0__sram3 2180 1140 
#addHaloToBlock 8 8 8 8 sram_inst/width_macro3_2__depth_macro3_0__sram3
#placeInstance sram_inst/width_macro3_3__depth_macro3_0__sram3 2180 1640 
#addHaloToBlock 8 8 8 8 sram_inst/width_macro3_3__depth_macro3_0__sram3

createRouteBlk -layer {met5} -box {50 50 2800 3250}
