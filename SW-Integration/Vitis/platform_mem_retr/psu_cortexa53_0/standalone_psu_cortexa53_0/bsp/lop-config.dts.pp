#line 2 "lop-config.dts"
/dts-v1/;
/ {
        compatible = "system-device-tree-v1,lop";
        lops {
                lop_0 {
                        compatible = "system-device-tree-v1,lop,load";
                        load = "assists/baremetal_validate_comp_xlnx.py";
                };

                lop_1 {
                    compatible = "system-device-tree-v1,lop,assist-v1";
                    node = "/";
                    outdir = "/home/maxim/Documents/Uni/BA/bachelor-thesis/SW-Integration/Vitis/platform_mem_retr/psu_cortexa53_0/standalone_psu_cortexa53_0/bsp";
                    id = "module,baremetal_validate_comp_xlnx";
                    options = "psu_cortexa53_0 /home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/lib/sw_services/xilfpga_v6_6/src /home/maxim/Documents/Uni/BA/bachelor-thesis/SW-Integration/Vitis/.wsdata/.repo.yaml";
                };

                lop_2 {
                    compatible = "system-device-tree-v1,lop,assist-v1";
                    node = "/";
                    outdir = "/home/maxim/Documents/Uni/BA/bachelor-thesis/SW-Integration/Vitis/platform_mem_retr/psu_cortexa53_0/standalone_psu_cortexa53_0/bsp";
                    id = "module,baremetal_validate_comp_xlnx";
                    options = "psu_cortexa53_0 /home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/lib/sw_services/xilsecure_v5_3/src /home/maxim/Documents/Uni/BA/bachelor-thesis/SW-Integration/Vitis/.wsdata/.repo.yaml";
                };

                lop_3 {
                    compatible = "system-device-tree-v1,lop,assist-v1";
                    node = "/";
                    outdir = "/home/maxim/Documents/Uni/BA/bachelor-thesis/SW-Integration/Vitis/platform_mem_retr/psu_cortexa53_0/standalone_psu_cortexa53_0/bsp";
                    id = "module,baremetal_validate_comp_xlnx";
                    options = "psu_cortexa53_0 /home/maxim/Xillinx/Vitis/2024.1/data/embeddedsw/lib/sw_services/xilmailbox_v1_9/src /home/maxim/Documents/Uni/BA/bachelor-thesis/SW-Integration/Vitis/.wsdata/.repo.yaml";
                };

        };
    };
