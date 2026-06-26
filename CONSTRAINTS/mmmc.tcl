# Version:1.0 MMMC View Definition File
# Do Not Remove Above Line
create_library_set -name slow_lib \
    -timing {/home/install/FOUNDRY/digital/45nm/dig/lib/slow.lib}

create_rc_corner -name rc_corner \
    -T 125

create_delay_corner -name delay_corner \
    -library_set slow_lib \
    -rc_corner rc_corner

create_constraint_mode -name func_mode \
    -sdc_files {outputs/top.sdc}

create_analysis_view -name slow_view \
    -constraint_mode func_mode \
    -delay_corner delay_corner

set_analysis_view \
    -setup {slow_view} \
    -hold {slow_view}
