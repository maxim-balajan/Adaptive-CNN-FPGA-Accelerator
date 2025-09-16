
cmake_minimum_required(VERSION 3.15)
project(bsp)
        
set(DRIVER_TARGETS axidma;scugic;zdma;sysmonpsu;axipmon;coresightps_dcc;resetps;clockps;csudma;ddrcpsu;dppsu;dpdma;gpiops;iicps;ipipsu;rtcpsu;sdps;spips;ttcps;uartps;usbpsu;wdtps)
set(DRIVER_LOCATIONS /home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/axidma_v9_18;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/scugic_v5_3;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/zdma_v1_18;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/sysmonpsu_v2_10;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/axipmon_v6_11;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/coresightps_dcc_v1_10;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/resetps_v1_7;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/clockps_v1_6;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/csudma_v1_15;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/ddrcpsu_v1_6;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/dppsu_v1_7;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/dpdma_v1_6;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/gpiops_v3_13;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/iicps_v3_19;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/ipipsu_v2_15;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/rtcpsu_v1_14;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/sdps_v4_3;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/spips_v3_10;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/ttcps_v3_19;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/uartps_v3_14;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/usbpsu_v1_15;/home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/XilinxProcessorIPLib/drivers/wdtps_v3_7)

list(LENGTH DRIVER_TARGETS no_of_drivers)
set(index 0)

while(${index} LESS ${no_of_drivers})
    list(GET DRIVER_TARGETS ${index} drv)
    list(GET DRIVER_LOCATIONS ${index} drv_dir)
    set(exp_dir "${drv_dir}/examples")
    add_custom_target(
        ${drv}_example ALL
        COMMAND lopper -f -O /home/maxim/Documents/Uni/BA/bachelor-thesis/SW-Integration/Vitis/platform_mem_retr/psu_cortexa53_0/standalone_psu_cortexa53_0/bsp/libsrc/${drv} /home/maxim/Documents/Uni/BA/bachelor-thesis/SW-Integration/Vitis/platform_mem_retr/psu_cortexa53_0/standalone_psu_cortexa53_0/bsp/hw_artifacts/psu_cortexa53_0_baremetal.dts -- bmcmake_metadata_xlnx psu_cortexa53_0 ${exp_dir} drvcmake_metadata
        BYPRODUCTS x${drv}_exlist.yaml)
    MATH(EXPR index "${index}+1")
endwhile()
