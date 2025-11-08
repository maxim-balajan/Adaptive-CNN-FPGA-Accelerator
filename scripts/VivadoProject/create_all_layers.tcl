# Define the root folder — change this or pass as an argument
if { $argc > 0 } {
    set root_dir [lindex $argv 0]
} else {
    set root_dir [pwd]
}

# Print which root folder is being scanned
puts "Scanning root directory: $root_dir"

# Get all subdirectories recursively
proc get_subdirs {dir} {
    set result {}
    foreach item [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $item]} {
            lappend result $item
            # Recurse into subdirectories
            set subdirs [get_subdirs $item]
            if {[llength $subdirs] > 0} {
                foreach subdir $subdirs {
                    lappend result $subdir
                }
            }
        }
    }
    return $result
}

# Iterate through each subfolder
set subdirs [get_subdirs $root_dir]
foreach dir $subdirs {
    set script_file [file join $dir create_project.tcl]
    if {[file exists $script_file]} {
        puts "\n--- Running $script_file of $dir ---"
        source $script_file

	puts "\n--- Closing Project inside of $dir ---"
	close_project
    }
}

puts "\nAll Layers have been created!\n"
