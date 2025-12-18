package chip_8din

import "core:os"
import "core:fmt"

Chip8 :: struct {
    display: [2048]byte,
    memory: [4096]byte,
    delay, sound: byte,
    v: [16]byte,
    i, pc, sp: u12,
}

vm: Chip8

chip8_init :: proc(file: string) {
    if file, success := os.read_entire_file(file); success {
        copy(vm.memory[0x200:0xea0], file)
        delete(file)
        vm.pc = 0x200
        vm.sp = 0xfff
    } else {
        fmt.eprintfln("Error al leer el archivo '%v'", file)
    }
}

check_bounds :: proc() -> bool{
    return vm.pc > 0x1ff && vm.pc < 0xea0
}

decrement_delay :: proc() {
    if vm.delay != 0 do vm.delay -= 1
}

fetch_instruction :: proc() -> u16 {
    inst := vm.memory[vm.pc: vm.pc + 2]
    vm.pc += 2

    opcode := u16(inst[1]) + (u16(inst[0]) << 8)
    return opcode;
}

execute_instruction :: proc(opcode: u16) {
    switch opcode {
    case 0x00e0:
        clear()
    case 0x00ee:
        ret()
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
        jumpz(nnn)
    // case 0xc000:
    case 0xd000..=0xdfff:
        x := get_vx_register(opcode)
        y := get_vy_register(opcode)
        n := get_n_value(opcode)
        draw(x, y, n)
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
        if nn == 0x1e { add(x) } else
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
