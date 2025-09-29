import os
from kernel_cores import KernelCores
from adder_tree_config import AdderTreeConfig
from core_tree import CoreTree
from routed_kernel_cores import RoutedKernelCores


import argparse

def parse_args():

    default_config = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'adder_tree_config.yaml')
    default_export = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'export')
    default_templates = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'templates')

    parser = argparse.ArgumentParser()
    
    parser.add_argument('-d', '--destination', type=str, default=default_export,
                        help=f"Destination path (default: {default_export})")
    parser.add_argument('-t', '--templates', type=str, default=default_templates,
                        help=f"Templates path (default: {default_templates})")
    parser.add_argument('-c', '--config', type=str, default=default_config,
                        help=f"Config file path (default: {default_config})")
    
    return parser.parse_args()

def main():

    args = parse_args()

    adder_config = AdderTreeConfig(args.config, args.templates, args.destination)

    kernel_cores = KernelCores(adder_config, args.templates, args.destination)

    for core in adder_config.cores:
        core.module_to_file()

    kernel_cores.module_to_file()

    print(" # kernel_cores.vhd successfully generated!")

    core_tree = CoreTree(adder_config, adder_config.route_configs, args.templates, args.destination, 0)

    core_tree.route()

    core_tree.module_to_file()

    print(" # routing_cores.vhd successfully generated!")

    routed_cores = RoutedKernelCores(kernel_cores, core_tree)

    routed_cores.module_to_file()

    print(" # routed_kernel_cores.vhd successfully_generated!")

    return 0



if __name__ == "__main__":
    main()