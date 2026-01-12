package chip_8din

import rl "vendor:raylib"

import "core:math"
import "core:c"

DISPLAY_WIDTH :: 0x40
DISPLAY_HEIGHT :: 0x20
PIXEL_SCALE :: 10

MAX_SAMPLES_PER_UPDATE :: 4096

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
    rl.InitWindow(DISPLAY_WIDTH * PIXEL_SCALE, DISPLAY_HEIGHT * PIXEL_SCALE, "chip-8din")
    rl.SetTargetFPS(c.int(fps))
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

display_render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK)

    for p, i in vm.display {
        x := (i32(i) % DISPLAY_WIDTH) * PIXEL_SCALE
        y := (i32(i) / DISPLAY_WIDTH) * PIXEL_SCALE
        if bool(p) do rl.DrawRectangle(x, y, PIXEL_SCALE, PIXEL_SCALE, rl.WHITE)
    }
    vm.wait = false
}

draw_sprite :: proc(x, y: u8, sprite: []byte) -> (flag: byte) {
    for i := 0; i < len(sprite); i += 1 {
        pixels: [8]byte
        value := sprite[i]
        get_pixels(pixels[:], value)
        if vm.variant == .CHIP_8 && y < 0x20 && y + u8(i) >= 0x20 do break
        for j in 0..<8 {
            if vm.variant == .CHIP_8 && x < 0x40 && x + u8(j) >= 0x40 do break
            pos_x := u16(x + u8(j)) % 0x40
            pos_y := u16(y + u8(i)) % 0x20
            pos_d := pos_x + (0x40 * pos_y)
            if pixel := pixels[j]; pixel != 0 do flag |= set_pixel(pos_d, pixel)
            // fmt.printfln("pixel %x, %x set to %x", pos_x, pos_y, vm.display[display_pos])
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
