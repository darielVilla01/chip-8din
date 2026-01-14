package chip_8din

import "core:strings"
import "core:math"
import "core:fmt"
import "core:os"

VM_Config :: struct {
    variant: Chip8_Variant,
    file_path: string,
    fps, ipf: int,
}

u8_slice_to_int :: proc(slice: []u8) -> (result: int, success: bool) {
    for i := 0; i < len(slice); i += 1 {
        digit := cast(int)(slice[len(slice) - (i + 1)] - 48)
        if success = digit >= 0 && digit <= 9; success {
            result += digit * cast(int)math.pow10(cast(f32)i)
        } else {
            return result, success
        }
    }
    return result, success
}

vm_configuration :: proc() -> (config: VM_Config) { 
    args := os.args
    if len(args) < 2 {
        print_help()
        return
    }
    for i := 1; i < len(args); i += 1 {
        if args[i] == "-variant" {
            i += 1
            variant := args[i]
            if variant == "chip8" do config.variant = .CHIP_8; else
            if variant == "super" do config.variant = .SUPER; else
            if variant == "xo" do config.variant = .XO; 
            else {
                fmt.printfln("Error: Invalid `{s}` variant given", transmute([]u8)variant)
                return VM_Config{}
            }
        }
        if args[i] == "-set-fps" {
            i += 1
            value_str := transmute([]u8)args[i]
            if value, ok := u8_slice_to_int(value_str); ok do config.fps = value; 
            else { 
                fmt.printfln("Error: Invalid argument for -set-fps '%s'", value_str)
                return VM_Config{}
            }
        } else
        if args[i] == "-set-cpf" {
            i += 1
            value_str := transmute([]u8)args[i]
            if value, ok := u8_slice_to_int(value_str); ok do config.ipf = value;
            else { 
                fmt.printfln("Error: Invalid argument for -set-ipf '%s'", value_str)
                return VM_Config{}
            }
        } else
        if args[i] == "-help" {
            print_help()
            return VM_Config{}
        } else 
        if strings.starts_with(args[i], "-") {
            fmt.printfln("Error: Unknown option '%s'", args[i])
            return VM_Config{}
        } 
        else {
            config.file_path = args[i]
        }
    }
    if config.fps == 0 do config.fps = 60
    if config.ipf == 0 do config.ipf = 60
    return config
}

print_help :: proc() {
    fmt.printfln(`
Simple implementation of a Chip-8 Virtual Machine written Odin
Usage: ./chip8din [OPTIONS...] rom_file

Options:
-variant [chip8|super|xo]   Set the chip8 variant to emulate (default: chip8)
-set-fps frames             Set the frames per second of the display (default: 60)
-set-cpf cycles             Set the cycles per frame of the virtual machine (default: 60)
-help                       Show this help message
    `)
}
