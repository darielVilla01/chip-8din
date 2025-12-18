package chip_8din

import "core:math/rand"
import "core:fmt"

u4 :: distinct u8
u12 :: distinct u16

/// Instructions
clear :: proc() { for &pixel in vm.display do pixel = 0 }
ret :: proc() {
    hi := u12(vm.memory[vm.sp + 1]) << 8
    lo := u12(vm.memory[vm.sp + 2])
    vm.sp += 2
    vm.pc = hi + lo
}
call :: proc(nnn: u12) {
    vm.memory[vm.sp] = u8(vm.pc & 0xff)
    vm.memory[vm.sp - 1] = u8(vm.pc >> 8)
    vm.sp -= 2
    vm.pc = nnn
}
beql_vx_nn :: proc(x: u4, nn:u8) { if vm.v[x] == nn do vm.pc += 2}
bneq_vx_nn :: proc(x: u4, nn:u8) { if vm.v[x] != nn do vm.pc += 2}
beql_vx_vy :: proc(x: u4, y:u4) { if vm.v[x] == vm.v[y] do vm.pc += 2}
bneq_vx_vy :: proc(x: u4, y:u4) { if vm.v[x] != vm.v[y] do vm.pc += 2}
load_vx_nn :: proc(x: u4, nn: u8) { vm.v[x] = nn }
load_vx_vy :: proc(x: u4, y: u4) { vm.v[x] = vm.v[y] }
or :: proc(x: u4, y:u4) { vm.v[x] |= vm.v[y] }
and :: proc(x: u4, y:u4) { vm.v[x] &= vm.v[y] }
xor :: proc(x: u4, y:u4) { vm.v[x] ~= vm.v[y] }
add_vx_vy :: proc(x: u4, y:u4) { 
    temp := vm.v[x]
    vm.v[x] += vm.v[y] 
    vm.v[0xf] = (temp + vm.v[y]) < temp ? 1: 0
}
add_vx_nn :: proc(x: u4, nn: u8) { vm.v[x] += nn }
sub_vx :: proc(x: u4, y:u4) { 
    temp := vm.v[x]
    vm.v[x] -= vm.v[y] 
    vm.v[0xf] = temp < vm.v[y] ? 0: 1
}
sub_vy :: proc(x: u4, y:u4) { 
    temp := vm.v[y]
    vm.v[x] = vm.v[y] - vm.v[x]
    vm.v[0xf] = temp < vm.v[x] ? 0: 1
}
shiftr :: proc(x: u4, y:u4) {
    temp := vm.v[y]
    vm.v[x] = vm.v[y] >> 1
    vm.v[0xf] = temp & 1
}
shiftl :: proc(x: u4, y:u4) {
    temp := vm.v[y]
    vm.v[x] = vm.v[y] << 1
    vm.v[0xf] = (temp & 0x80) >> 7
}
load_i_nnn :: proc(nnn: u12) { vm.i = nnn }
jump :: proc(nnn: u12) { vm.pc = nnn }
jumpz :: proc(nnn: u12) { vm.pc = (nnn + u12(vm.v[0])) % 0x1000 }
rand :: proc(x: u4, nn: u8) { vm.v[x] = cast(u8)rand.uint_max(256) & nn }
draw :: proc(x, y, n: u4) { vm.v[0xf] = draw_sprite(vm.v[x], vm.v[y], vm.memory[vm.i: vm.i + u12(n)]) }
bkey :: proc(x: u4) { if is_key_pressed(vm.v[x]) do vm.pc += 2}
bnkey :: proc(x: u4) { if !is_key_pressed(vm.v[x]) do vm.pc += 2}
get_key :: proc(x: u4) { 
    if key, pressed := get_keypad_input(); pressed {
        vm.v[x] = key
    } else {
        vm.pc -= 2
    }
}
set_delay :: proc(x: u4) { vm.delay = vm.v[x] }
set_sound :: proc(x: u4) { vm.sound = vm.v[x] }
get_delay :: proc(x: u4) { vm.v[x] = vm.delay}
add_i_vx :: proc(x: u4) { vm.i += u12(vm.v[x]) }
bcd :: proc(x: u4) {
    vm.memory[vm.i] = vm.v[x] / 100
    vm.memory[vm.i + 1] = (vm.v[x] / 10) % 10
    vm.memory[vm.i + 2] = vm.v[x] % 10
}
save :: proc(x: u4) {
    for i: u12 = 0; i <= u12(x); i += 1 do vm.memory[vm.i + i] = vm.v[i]
    vm.i += u12(x) + 1
}
load_vx :: proc(x: u4) {
    for i: u12 = 0; i <= u12(x); i += 1 do vm.v[i] = vm.memory[vm.i + i]
    vm.i += u12(x) + 1
}

/// Instruction groups
beql :: proc{
    beql_vx_nn,
    beql_vx_vy,
}
bneq :: proc{
    bneq_vx_nn,
    bneq_vx_vy,
}
load :: proc{
    load_vx_nn,
    load_vx_vy,
    load_i_nnn,
    load_vx
}
add :: proc{
    add_vx_nn,
    add_vx_vy,
    add_i_vx
}
