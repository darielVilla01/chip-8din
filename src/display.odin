package chip_8din

import rl "vendor:raylib"

import "core:fmt"
import "core:math"
import "core:c"

DISPLAY_WIDTH :: 0x400
DISPLAY_HEIGHT :: 0x200
PIXEL_SCALE :: 16

MAX_SAMPLES_PER_UPDATE :: 4096

@(private="file")
display: []byte

@(private="file")
pixel_res, width_res, height_res: i32

@(private="file")
stream: rl.AudioStream

@(private="file")
sineIdx: c.float = 0

@(private="file")
AudioInputCallback :: proc "c" (buffer: rawptr, frames: c.uint)
{
    audioFrequency: c.float = 400.0

    incr := audioFrequency/42100.0
    d: [^]c.short = cast(^c.short)buffer

    for i: c.uint = 0; i < frames; i += 1 {
        d[i] = cast(c.short)(32000*math.sin(2*math.PI*sineIdx))
        sineIdx += incr
        if sineIdx > 1 do sineIdx -= 1
    }
}

display_init :: proc(fps: int) {
    rl.InitWindow(DISPLAY_WIDTH, DISPLAY_HEIGHT, "chip-8din")
    rl.SetTargetFPS(c.int(fps))
    display_lores()

    rl.InitAudioDevice()
    rl.SetAudioStreamBufferSizeDefault(MAX_SAMPLES_PER_UPDATE)
    stream = rl.LoadAudioStream(42100, 16, 1)
    rl.SetAudioStreamCallback(stream, AudioInputCallback)
}

display_deinit :: proc() {
    rl.UnloadAudioStream(stream)
    rl.CloseAudioDevice()
    rl.CloseWindow()
}

display_sound :: proc() {
    if rl.IsAudioStreamPlaying(stream) && vm.sound <= 1 do rl.StopAudioStream(stream)
    if !rl.IsAudioStreamPlaying(stream) && vm.sound > 1 do rl.PlayAudioStream(stream)
}

display_running :: proc() -> bool { return !rl.WindowShouldClose() }

display_hires :: proc() {
    display = vm.display[:]
    pixel_res = PIXEL_SCALE / 2
    width_res = DISPLAY_WIDTH / pixel_res
    height_res = DISPLAY_HEIGHT / pixel_res
    when ODIN_DEBUG {
        fmt.printfln("hires %d, %d", width_res, height_res)
    }
    vm.res = {128,64}
}

display_lores :: proc() {
    display = vm.display[:2048]
    pixel_res = PIXEL_SCALE
    width_res = DISPLAY_WIDTH / pixel_res
    height_res = DISPLAY_HEIGHT / pixel_res
    when ODIN_DEBUG {
        fmt.printfln("lores %d, %d", width_res, height_res)
    }
    vm.res = {64,32}
}

display_render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK) 

    for p, i in display {
        x := (i32(i) % width_res) * pixel_res
        y := (i32(i) / width_res) * pixel_res
        if bool(p) do rl.DrawRectangle(x, y, pixel_res, pixel_res, rl.WHITE)
    }
    vm.wait = false
}

draw_sprite :: proc(x, y: u8, sprite: []byte) -> (flag: byte) {
    for i := 0; i < len(sprite); i += 1 {
        pixels: [8]byte
        value := sprite[i]
        get_pixels(pixels[:], value)
        if vm.variant != .XO && y < cast(u8)height_res && y + u8(i) >= cast(u8)height_res do break
        for j in 0..<8 {
            if vm.variant != .XO && x < cast(u8)width_res && x + u8(j) >= cast(u8)width_res do break
            pos_x := i32(x + u8(j)) % width_res
            pos_y := i32(y + u8(i)) % height_res
            pos_d := cast(u16)(pos_x + (width_res * pos_y))
            if pixel := pixels[j]; pixel != 0 do flag |= set_pixel(pos_d, pixel)

            when ODIN_DEBUG {
                fmt.printfln("pixel %x, %x set to %x", pos_x, pos_y, vm.display[pos_d])
            }
        }
    }
    return flag
}

get_pixels :: proc(pixels: []byte, value: byte) {
    if bool(value & 0x80) do pixels[0] = 0xff 
    if bool(value & 0x40) do pixels[1] = 0xff 
    if bool(value & 0x20) do pixels[2] = 0xff 
    if bool(value & 0x10) do pixels[3] = 0xff 
    if bool(value & 0x08) do pixels[4] = 0xff 
    if bool(value & 0x04) do pixels[5] = 0xff 
    if bool(value & 0x02) do pixels[6] = 0xff 
    if bool(value & 0x01) do pixels[7] = 0xff 
}

set_pixel :: proc(index: u16, pixel: byte) -> (flag: byte) {
    flag = vm.display[index] != 0 ? 1: 0 
    vm.display[index] ~= pixel
    return
}
