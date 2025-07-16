import os
from kernel_cores import KernelCores
from adder_tree_config import AdderTreeConfig


def main():

    adder_config = AdderTreeConfig(os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'adder_tree_config.yaml'))

    kernel_cores = KernelCores(adder_config)

    for core in adder_config.cores:
        core.module_to_file()

    kernel_cores.module_to_file()

    print("Files successfully generated!")

    return 0



if __name__ == "__main__":
    main()