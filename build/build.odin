#+feature dynamic-literals

package NormEngine

import path "core:path/filepath"
import "core:fmt"
import "core:os/os2"
import "core:os"
import "core:strings"
import "core:log"
import "core:reflect"
import "core:time"

import utils "../core/utils"

EXE_NAME :: "NormEngine"

Target :: enum {
    windows,
    linux,
    mac,
}

Mode :: enum {
    cli,
    gui,
}

main :: proc() {
    start_time := time.now()

    // Parse arguments
    mode := Mode.cli
    should_run := false
    clean_build := false
    
    for arg in os2.args {
        if arg == "gui" {
            mode = .gui
        } else if arg == "cli" {
            mode = .cli
        } else if arg == "run" {
            should_run = true
        } else if arg == "clean" {
            clean_build = true
        }
    }

    // Determine target platform
    assert(ODIN_OS == .Windows || ODIN_OS == .Darwin || ODIN_OS == .Linux, "unsupported OS target")
    target: Target
    #partial switch ODIN_OS {
        case .Windows: target = .windows
        case .Linux: target = .linux
        case .Darwin: target = .mac
        case: {
            log.error("Unsupported os:", ODIN_OS)
            return
        }
    }
    
    fmt.println("Building for", target, "in", mode, "mode")

    // Generate the generated.odin file
    {
        file := "core/generated.odin"
        f, err := os.open(file, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
        if err != nil {
            fmt.eprintln("Error:", err)
        }
        defer os.close(f)
        
        using fmt
        fprintln(f, "//")
        fprintln(f, "// MACHINE GENERATED via build.odin")
        fprintln(f, "// do not edit by hand!")
        fprintln(f, "//")
        fprintln(f, "")
		fprintln(f, "package NormEngineCore")
        fprintln(f, "")
        fprintln(f, "Platform :: enum {")
        fprintln(f, "	windows,")
        fprintln(f, "	linux,")
        fprintln(f, "	mac,")
        fprintln(f, "}")
        fprintln(f, tprintf("PLATFORM :: Platform.%v", target))
        fprintln(f, "")
        fprintln(f, "Mode :: enum {")
        fprintln(f, "	cli,")
        fprintln(f, "	gui,")
        fprintln(f, "}")
        fprintln(f, tprintf("BUILD_MODE :: Mode.%v", mode))
    }

    wd := os.get_current_directory()
    utils.make_directory_if_not_exist("build")
    
    out_dir : string
    exe_suffix := mode == .gui ? "_gui" : "_cli"
    switch target {
        case .windows: out_dir = fmt.tprintf("build/windows_debug")
        case .linux: out_dir = fmt.tprintf("build/linux_debug")
        case .mac: out_dir = fmt.tprintf("build/mac_debug")
    }

    full_out_dir_path := fmt.tprintf("%v/%v", wd, out_dir)
    log.info(full_out_dir_path)
    
    // Clean if requested
    if clean_build {
        if os.exists(out_dir) {
            os.remove_directory(out_dir)
        }
    }
    
    utils.make_directory_if_not_exist(full_out_dir_path)

    // Build command
    {
        c: [dynamic]string = {
            "odin",
            "build",
            ".",
            "-debug",
            fmt.tprintf("-out:%v/%v%v.exe", out_dir, EXE_NAME, exe_suffix),
        }
        utils.fire(..c[:])
    }

    // Create launcher scripts for both modes
    {
        cli_launcher := fmt.tprintf(
            "@echo off\ncd %v\n%v_cli.exe %%*\npause",
            out_dir, EXE_NAME
        )
        gui_launcher := fmt.tprintf(
            "@echo off\ncd %v\n%v_gui.exe %%*\npause",
            out_dir, EXE_NAME
        )
        
        switch target {
            case .windows:
                os.write_entire_file("run_cli.bat", transmute([]u8)cli_launcher)
                os.write_entire_file("run_gui.bat", transmute([]u8)gui_launcher)
            case .linux:
                os.write_entire_file("run_cli.sh", transmute([]u8)cli_launcher)
                os.write_entire_file("run_gui.sh", transmute([]u8)gui_launcher)
            case .mac:
                cli_launcher = fmt.tprintf(
                    "#!/bin/bash\ncd %v\n./%v_cli.exe \"$@\"",
                    out_dir, EXE_NAME
                )
                gui_launcher = fmt.tprintf(
                    "#!/bin/bash\ncd %v\n./%v_gui.exe \"$@\"",
                    out_dir, EXE_NAME
                )
                os.write_entire_file("run_cli.sh", transmute([]u8)cli_launcher)
                os.write_entire_file("run_gui.sh", transmute([]u8)gui_launcher)
                utils.fire("chmod", "+x", "run_cli.sh")
                utils.fire("chmod", "+x", "run_gui.sh")
        }
    }
    
    if should_run {
        fmt.println("Running executable...")
        switch target {
            case .windows:
                utils.fire("cmd", "/c", fmt.tprintf("cd %v && %v%v.exe", out_dir, EXE_NAME, exe_suffix))
            case .linux:
                utils.fire("konsole", "/c", fmt.tprintf("cd %v && %v%v.AppImage", out_dir, EXE_NAME, exe_suffix))
            case .mac:
                utils.fire("bash", "-c", fmt.tprintf("cd %v && ./%v%v.exe", out_dir, EXE_NAME, exe_suffix))
        }
    }

    fmt.println("DONE in", time.diff(start_time, time.now()))
}


// value extraction example:
/*
target: Target
found: bool
for arg in os2.args {
	if strings.starts_with(arg, "target:") {
		target_string := strings.trim_left(arg, "target:")
		value, ok := reflect.enum_from_name(Target, target_string)
		if ok {
			target = value
			found = true
			break
		} else {
			log.error("Unsupported target:", target_string)
		}
	}
}
*/