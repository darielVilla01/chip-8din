package chip_8din

import "core:os"
import "core:fmt"

Chip8_Variant :: enum { CHIP_8, SUPER, XO }

Chip8 :: struct {
    variant: Chip8_Variant,
    display: [0x2000]byte,
    memory: [0x1000]byte,
    stack: [32]byte,
    vregs: [16]byte,
    res: [2]byte,
    delay, sound: byte,
    i, pc, sp: u12,
    wait: bool,
}

@(private="file")
hex_font: []byte = {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // a
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // b
    0xF0, 0x80, 0x80, 0x80, 0xF0, // c
    0xE0, 0x90, 0x90, 0x90, 0xE0, // d
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // e
    0xF0, 0x80, 0xF0, 0x80, 0x80  // f
}

vm: Chip8

chip8_init :: proc(config: VM_Config) {
    if file, success := os.read_entire_file(config.file_path); success {
        copy(vm.memory[0x100:0x150], hex_font)
        copy(vm.memory[0x200:], file)
        delete(file)
        vm.variant = config.variant
        vm.pc = 512
        vm.sp = 31
    } else {
        fmt.eprintfln("Error al leer el archivo '%v'", file)
    }
}

pc_is_valid :: proc() -> bool{
    upper_limit: u12 = vm.variant == .CHIP_8 ? 0xea0: vm.variant == .SUPER ? 0xfff: 0xffff
    return vm.pc > 0x1ff && vm.pc < upper_limit
}

decrement_timers :: proc() {
    if vm.delay != 0 do vm.delay -= 1
    if vm.sound != 0 do vm.sound -= 1
}

fetch_instruction :: proc() -> u16 {
    inst := vm.memory[vm.pc: vm.pc + 2]
    vm.pc += 2

    opcode := u16(inst[1]) + (u16(inst[0]) << 8)
    return opcode;
}

execute_instruction :: proc(opcode: u16) {
    switch opcode {
    case 0x00c0..=0x00cf:
        if vm.variant != .CHIP_8 {
            n := get_n_value(opcode)
            scroll_down(n)
        } else {
            fmt.printfln("Invalid opcode %X", opcode)
            vm.pc = 0
        }
    case 0x00e0:
        clear()
    case 0x00ee:
        ret()
    case 0x00fb:
        if vm.variant != .CHIP_8 {
            scroll_right()
        } else {
            fmt.printfln("Invalid opcode %X", opcode)
            vm.pc = 0
        }
    case 0x00fc:
        if vm.variant != .CHIP_8 {
            scroll_left()
        } else {
            fmt.printfln("Invalid opcode %X", opcode)
            vm.pc = 0
        }
    case 0x00fd:
        vm.pc = 0
    case 0x00fe:
        if vm.variant != .CHIP_8 {
            display_lores()
        } else {
            fmt.printfln("Invalid opcode %X", opcode)
            vm.pc = 0
        }
    case 0x00ff:
        if vm.variant != .CHIP_8 {
            display_hires()
        } else {
            fmt.printfln("Invalid opcode %X", opcode)
            vm.pc = 0
        }
    case 0x1000..=0x1fff:
        nnn := get_nnn_addr(opcode)
        jump(nnn)
    case 0x2000..=0x2fff:
        nnn := get_nnn_addr(opcode)
        call(nnn)
    case 0x3000..=0x3fff:
        x := get_vx_register(opcode)
        nn := get_nn_value(opcode)
        beql(x, nn)
    case 0x4000..=0x4fff:
        x := get_vx_register(opcode)
        nn := get_nn_value(opcode)
        bneq(x, nn)
    case 0x5000..=0x5fff:
        x := get_vx_register(opcode)
        y := get_vy_register(opcode) 
        if n := get_n_value(opcode); n == 0 { beql(x, y) }
        else {
            fmt.printfln("opcode %X not implemented", opcode)
            vm.pc = 0
        }
    case 0x6000..=0x6fff:
        x := get_vx_register(opcode)
        nn := get_nn_value(opcode)
        load(x, nn)
    case 0x7000..=0x7fff:
        x := get_vx_register(opcode)
        nn := get_nn_value(opcode)
        add(x, nn)
    case 0x8000..=0x8fff:
        x := get_vx_register(opcode)
        y := get_vy_register(opcode) 
        n := get_n_value(opcode)
        if n == 0 { load(x, y) } else
        if n == 1 { or(x, y) } else
        if n == 2 { and(x, y) } else
        if n == 3 { xor(x, y) } else
        if n == 4 { add(x, y) } else
        if n == 5 { sub_vx(x, y) } else
        if n == 6 { shiftr(x, y) } else
        if n == 7 { sub_vy(x, y) } else
        if n == 0xe { shiftl(x, y) } else
        {
            fmt.printfln("opcode %X not implemented", opcode)
            vm.pc = 0
        }
    case 0x9000..=0x9fff:
        x := get_vx_register(opcode)
        y := get_vy_register(opcode)
        if n := get_n_value(opcode); n == 0 { bneq(x, y) }
        else {
            fmt.printfln("opcode %X not implemented", opcode)
            vm.pc = 0
        }
    case 0xa000..=0xafff:
        nnn := get_nnn_addr(opcode)
        load(nnn)
    case 0xb000..=0xbfff:
        nnn :=  get_nnn_addr(opcode)
        if vm.variant != .SUPER { 
            jump(0, nnn) 
        } else {
            x := get_vx_register(opcode)
            jump(x, nnn) 
        }
    case 0xc000..=0xcfff:
        x := get_vx_register(opcode)
        nn :=  get_nn_value(opcode)
        rand(x, nn)
    case 0xd000..=0xdfff:
        x := get_vx_register(opcode)
        y := get_vy_register(opcode)
        n := get_n_value(opcode)
        draw(x, y, n)
        if vm.variant == .CHIP_8 do vm.wait = true
    case 0xe000..=0xefff:
        x := get_vx_register(opcode)
        nn := get_nn_value(opcode)
        if nn == 0x9e { bkey(x) } else
        if nn == 0xa1 { bnkey(x) } else 
        {
            fmt.printfln("opcode %X not implemented", opcode)
            vm.pc = 0
        }
    case 0xf000..=0xffff:
        x := get_vx_register(opcode)
        nn := get_nn_value(opcode)
        if nn == 0x07 { get_delay(x) } else
        if nn == 0x0a { get_key(x) } else
        if nn == 0x15 { set_delay(x) } else
        if nn == 0x18 { set_sound(x) } else
        if nn == 0x1e { add(x) } else
        if nn == 0x29 { hex(x) } else
        if nn == 0x33 { bcd(x) } else
        if nn == 0x55 { save(x) } else
        if nn == 0x65 { load(x) } else
        {
            fmt.printfln("opcode %X not implemented", opcode)
            vm.pc = 0
        }
    case:
        fmt.printfln("opcode %X not implemented", opcode)
        vm.pc = 0
    }
}

get_vx_register :: proc(opcode: u16) -> u4 {
    vx := u4((opcode & 0x0f00) >> 8)
    return vx
}

get_vy_register :: proc(opcode: u16) -> u4 {
    vy := u4((opcode & 0x00f0) >> 4)
    return vy
}

get_n_value :: proc(opcode: u16) -> u4 {
    n := u4(opcode & 0x000f)
    return n
}

get_nn_value :: proc(opcode: u16) -> u8 {
    nn := u8(opcode & 0x00ff)
    return nn
}
get_nnn_addr :: proc(opcode: u16) -> u12 {
    nnn := u12(opcode & 0x0fff)
    return nnn
}
