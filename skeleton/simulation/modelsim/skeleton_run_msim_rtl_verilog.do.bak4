transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/vga_data.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/VGA_Audio_PLL.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/Reset_Delay.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/skeleton.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/PS2_Interface.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/PS2_Controller.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/processor.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/pll.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/imem.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/Hexadecimal_To_Seven_Segment.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/dmem.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/Altera_UP_PS2_Data_In.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/Altera_UP_PS2_Command_Out.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/vga_controller.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/video_sync_generator.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/img_index.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/img_data.v}
vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton/db {C:/Users/Student/Desktop/real_flappy_bird/skeleton/db/pll_altpll.v}
vlog -sv -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton {C:/Users/Student/Desktop/real_flappy_bird/skeleton/lcd.sv}

vlog -vlog01compat -work work +incdir+C:/Users/Student/Desktop/real_flappy_bird/skeleton/output_files {C:/Users/Student/Desktop/real_flappy_bird/skeleton/output_files/flappy_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  flappy_tb

add wave *
view structure
view signals
run -all
