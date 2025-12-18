package chip_8din

import "core:math"
import rl "vendor:raylib"

DISPLAY_WIDTH :: 0x40
DISPLAY_HEIGHT :: 0x20
PIXEL_SCALE :: 10

beep: rl.AudioStream
sineIdx: f64

display_init :: proc() {
    rl.InitWindow(DISPLAY_WIDTH * PIXEL_SCALE, DISPLAY_HEIGHT * PIXEL_SCALE, "chip-8din")
    rl.SetTargetFPS(60)
}

audio_input_callback ::  proc "c" (buffer: rawptr, frames: u32) {
    incr: f64 = 440 / 44100
    d: [^]i16 = cast(^i16)buffer

    for i: u32 = 0; i < frames; i += 1 {
        d[i] = i16(32000 * math.sin(2*math.PI*sineIdx))
        sineIdx += incr
        if sineIdx > 1.0 do sineIdx = -1.0
    }
}

audio_init :: proc() {
    rl.InitAudioDevice()
    rl.SetAudioStreamBufferSizeDefault(4096)
    beep = rl.LoadAudioStream(44100, 16, 1)
    rl.SetAudioStreamCallback(beep, audio_input_callback)
}

audio_play :: proc() {
    if vm.sound > 1 {
        rl.PlayAudioStream(beep)
    } else {
        rl.StopAudioStream(beep)
    }
}

audio_deinit :: proc() {
    rl.UnloadAudioStream(beep)
    rl.CloseAudioDevice()
}

display_deinit :: proc() {
    rl.CloseWindow()
}

display_running :: proc() -> bool { return rl.WindowShouldClose() }

display_render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK)

    for p, i in vm.display {
        x := (i32(i) % DISPLAY_WIDTH) * PIXEL_SCALE
        y := (i32(i) / DISPLAY_WIDTH) * PIXEL_SCALE
        if bool(p) do rl.DrawRectangle(x, y, PIXEL_SCALE, PIXEL_SCALE, rl.WHITE)
    }
}

draw_sprite :: proc(x, y: u8, sprite: []byte) -> (flag: byte) {
    for i := 0; i < len(sprite); i += 1 {
        pixels: [8]byte
        value := sprite[i]
        get_pixels(pixels[:], value)
        for j in 0..<8 {
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
