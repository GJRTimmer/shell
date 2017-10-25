# Module: shell
#
# Subcommands
#   exec
#   linux
#   windows
namespace eval shell {
    procedure {execute} {
        -description
            "Execute shell command"
        -example
            "shell::exec <command>\n
            shell::exec -background <command>"
        -args {
            {
                -trim
                -type none
                -optional
                -description "Trim newlines from command result"
            }
            {
                -background
                -type none
                -optional
                -description "Run in background"
            }
            {
                command
                -type string
                -mandatory
                -description "Command to execute"
            }
        }
    } {
        set shellType "linux"
        set redirect "[namespace current]::%s"
        if { $background } {
            append redirect " -background"
        }
        
        if { [info exists site] } {
            append redirect " -site $site"
        }
        
        if { $trim } {
            append redirect " -trim"
        }
        
        append redirect " [list $command]"
        
        if { [string tolower $::tcl_platform(platform)] eq "windows" } {
            set shellType windows
        }
        
        return [eval [format $redirect $shellType]]        
    }
    
    procedure {linux} {
        -description
            "Execute command\nOS: Linux\nType: \$SHELL"
        -example
            "shell::linux <command>\n
            shell::linux -background <command>"
        -args {
            {
                -trim
                -type none
                -optional
                -description "Trim newlines from command result"
            }
            {
                -background
                -type none
                -optional
                -description "Run in background"
            }
            {
                command
                -type string
                -mandatory
                -description "Command to execute"
            }
        }
    } {        
        set result [dict create]
        
        # Linux/Unix Shell
        switch -exact -- $background {
            0 {
                set code [catch {exec {*}"$command"} res]
            }
            1 {
                set cmd [format "nohup %s > /dev/null 2>&1" $command]
                set code [catch {exec {*}$cmd} res]
            }
            default {
                throw {SHELL INVALID} "Invalid value for argument 'background'"
            }
        }
        dict set result CODE $code
        if { $trim } {
            regsub -all "\n" $res " " res
            set res [string trimleft $res " "]
        }
        dict set result RESULT $res
        
        return $result
    }
    
    procedure {windows} {
        -description
            "Execute command\n
            OS: Windows\n
            Type: PowerShell"
        -example
            "shell::windows <command>\n
            shell::windows -background <command>"
        -args {
            {
                -trim
                -type none
                -optional
                -description "Trim newlines from command result"
            }
            {
                -background
                -type none
                -optional
                -description "Run in background"
            }
            {
                command
                -type string
                -mandatory
                -description "Command to execute"
            }
        }
    } {
        if { !([string tolower $::tcl_platform(platform)] eq "windows") } {
            throw {OS NOTSUPPORTED} "Powershell not supported under Linux/Unix"
        }
        
        set ps [file normalize [file join $::env(SystemRoot) system32 WindowsPowerShell v1.0 powershell.exe]]
        
        if { ![file exists $ps] } {
            throw {TCL FILE NOTFOUND} "powershell.exe not found"
        }
        
        # Set Background
        if { $background && [string index $command 0] ne "&" } {
            set command [format "&%s" $command]
        }
        
        set result [dict create]
        try {
            set code [catch {exec $ps -Command $command} res]
            dict set result CODE $code
            if { $trim } {
                regsub -all "\n" $res " " res
                set res [string trimleft $res " "]
            }
            dict set result RESULT $res
        } trap NONE errOut {
            # $errOut now holds the message that was written to stderr
            # and everything written to stdout!
            dict set result ERROR $errOut
        } trap CHILDKILLED {- opts} {
            lassign [dict get $opts -errorcode] -> pid signal msg
            # process $pid was killed by signal $signal; message is $msg
            dict set result ERROR "CHILDKILLED"
            dict set result MESSAGE $msg
            dict set result PID $pid
            dict set result SIGNAL $signal
        } trap CHILDSUSP {- opts} {
             lassign [dict get $opts -errorcode] -> pid signal msg
            # process $pid was suspended by signal $sigName; message is $msg
            dict set result ERROR "CHILDSUSP"
            dict set result MESSAGE $msg
            dict set result PID $pid
            dict set result SIGNAL $signal
        } trap POSIX {- opts} {
            lassign [dict get $opts -errorcode] -> errName msg
            # Some kind of kernel failure; details in $errName and $msg
            dict set result ERROR $errName
            dict set result MESSAGE $msg
        }
        
        return $result
    }
}
