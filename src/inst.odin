package chip_8din

import "core:math/rand"
import "core:fmt"

u4 :: distinct u8
u12 :: distinct u16
F :: 15

/// Instructions
scroll_down :: proc(n: u4) { scroll_pixels(i32(n), .Down) }
scroll_up :: proc(n: u4) { scroll_pixels(i32(n), .Up) }
scroll_right :: proc() { scroll_pixels(4, .Right) }
scroll_left :: proc() { scroll_pixels(4, .Left) }
clear :: proc() { for &pixel in vm.display do pixel = 0 }
ret :: proc() {
    hi := u12(vm.stack[vm.sp + 1]) << 8
    lo := u12(vm.stack[vm.sp + 2])
    vm.sp += 2
    vm.pc = hi + lo
}
call :: proc(nnn: u12) {
    vm.stack[vm.sp] = u8(vm.pc & 0xff)
    vm.stack[vm.sp - 1] = u8(vm.pc >> 8)
    vm.sp -= 2
    vm.pc = nnn
}
beql_vx_nn :: proc(x: u4, nn:u8) { if vm.vregs[x] == nn do vm.pc += 2}
bneq_vx_nn :: proc(x: u4, nn:u8) { if vm.vregs[x] != nn do vm.pc += 2}
beql_vx_vy :: proc(x: u4, y:u4) { if vm.vregs[x] == vm.vregs[y] do vm.pc += 2}
bneq_vx_vy :: proc(x: u4, y:u4) { if vm.vregs[x] != vm.vregs[y] do vm.pc += 2}
load_vx_nn :: proc(x: u4, nn: u8) { vm.vregs[x] = nn }
load_vx_vy :: proc(x: u4, y: u4) { vm.vregs[x] = vm.vregs[y] }
or :: proc(x: u4, y:u4) { 
    vm.vregs[x] |= vm.vregs[y] 
    if vm.variant == .CHIP_8 do vm.vregs[F] = 0
}
and :: proc(x: u4, y:u4) { 
    vm.vregs[x] &= vm.vregs[y] 
    if vm.variant == .CHIP_8 do vm.vregs[F] = 0
}
xor :: proc(x: u4, y:u4) { 
    vm.vregs[x] ~= vm.vregs[y] 
    if vm.variant == .CHIP_8 do vm.vregs[F] = 0
}
add_vx_vy :: proc(x: u4, y:u4) { 
    temp := vm.vregs[x]
    vm.vregs[x] += vm.vregs[y] 
    vm.vregs[F] = (temp + vm.vregs[y]) < temp ? 1: 0
}
add_vx_nn :: proc(x: u4, nn: u8) { vm.vregs[x] += nn }
sub_vx :: proc(x: u4, y:u4) { 
    temp := vm.vregs[x]
    vm.vregs[x] -= vm.vregs[y] 
    vm.vregs[F] = temp < vm.vregs[y] ? 0: 1
}
sub_vy :: proc(x: u4, y:u4) { 
    temp := vm.vregs[y]
    vm.vregs[x] = vm.vregs[y] - vm.vregs[x]
    vm.vregs[F] = temp < vm.vregs[x] ? 0: 1
}
shiftr :: proc(x: u4, y:u4) { 
    temp := vm.variant != .SUPER ? vm.vregs[y]: vm.vregs[x]
    vm.vregs[x] = temp >> 1
    vm.vregs[F] = temp & 1
}
shiftl :: proc(x: u4, y:u4) {
    temp := vm.variant != .SUPER ? vm.vregs[y]: vm.vregs[x]
    vm.vregs[x] = temp << 1
    vm.vregs[F] = (temp & 0x80) >> 7
}
load_i_nnn :: proc(nnn: u12) { vm.i = nnn }
jump_nnn :: proc(nnn: u12) { vm.pc = nnn }
jump_vx_nnn :: proc(x: u4, nnn: u12) { vm.pc = (nnn + u12(vm.vregs[x])) % 0x1000 }
rand :: proc(x: u4, nn: u8) { vm.vregs[x] = cast(u8)rand.uint_max(256) & nn }
draw :: proc(x, y, n: u4) { 
    upper_bound := n == 0 && vm.variant != .CHIP_8 ? vm.i + 32: vm.i + u12(n)
    vm.vregs[F] = draw_sprite(vm.vregs[x], vm.vregs[y], vm.memory[vm.i: upper_bound]) 
}
bkey :: proc(x: u4) { if is_key_pressed(vm.vregs[x]) do vm.pc += 2}
bnkey :: proc(x: u4) { if !is_key_pressed(vm.vregs[x]) do vm.pc += 2}
get_key :: proc(x: u4) { 
    if key, pressed := get_keypad_input(); pressed {
        vm.vregs[x] = key
    } else {
        vm.pc -= 2
    }
}
set_delay :: proc(x: u4) { vm.delay = vm.vregs[x] }
set_sound :: proc(x: u4) { vm.sound = vm.vregs[x] }
get_delay :: proc(x: u4) { vm.vregs[x] = vm.delay}
add_i_vx :: proc(x: u4) { vm.i += u12(vm.vregs[x]) }
hex :: proc(x: u4) { vm.i = 0x50 + (u12(vm.vregs[x]) * 5) }
bighex :: proc(x: u4) { vm.i = 0x100 + (u12(vm.vregs[x]) * 10) }
bcd :: proc(x: u4) {
    vm.memory[vm.i] = vm.vregs[x] / 100
    vm.memory[vm.i + 1] = (vm.vregs[x] / 10) % 10
    vm.memory[vm.i + 2] = vm.vregs[x] % 10
}
save :: proc(x: u4) {
    for i: u12 = 0; i <= u12(x); i += 1 do vm.memory[vm.i + i] = vm.vregs[i]
    if vm.variant != .SUPER do vm.i += u12(x) + 1
}
load_vx :: proc(x: u4) {
    for i: u12 = 0; i <= u12(x); i += 1 do vm.vregs[i] = vm.memory[vm.i + i]
    if vm.variant != .SUPER do vm.i += u12(x) + 1
}
saveflags :: proc(x: u4) {
    for i: u12 = 0; i <= u12(x); i += 1 do vm.flags[i] = vm.vregs[i]
}
loadflags :: proc(x: u4) {
    for i: u12 = 0; i <= u12(x); i += 1 do vm.vregs[i] = vm.flags[i]
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
jump :: proc{
    jump_nnn,
    jump_vx_nnn
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
