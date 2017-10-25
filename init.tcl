# shell::init.tcl
#
#	File to provide package loading
#
#
# Author: 	G.J.R. Timmer
# Date: 	2017-10-09
#


if { ![package vsatisfies [package provide Tcl] 8.6] } {return}
if { ![package vsatisfies [package require tepam] 0.5] } {return}

package provide shell 1.0.0

namespace eval shell {
    namespace import ::tepam::*
}

foreach file {
    shell.tcl
} {
    source [file join [file dirname [info script]] $file]
}
unset -nocomplain file

# EOF