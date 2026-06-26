################################################################################
#
# Init setup file
# Created by Genus(TM) Synthesis Solution on 06/14/2026 10:17:24
#
################################################################################

      if { ![is_common_ui_mode] } {
        error "This script must be loaded into an 'innovus -stylus' session."
      }
    


read_mmmc outputs/top_innovus.mmmc.tcl

read_netlist outputs/top_innovus.v

init_design
