package chip_8din

import rl "vendor:raylib"

import "core:fmt"
import "core:math"
import "core:c"

PIXEL_SCALE :: 16
DISPLAY_WIDTH :: 0x40 * PIXEL_SCALE
DISPLAY_HEIGHT :: 0x20 * PIXEL_SCALE

MAX_SAMPLES_PER_UPDATE :: 4096

ScrollDir :: enum {Left, Right, Up, Down}

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
    pixel_res = PIXEL_SCALE / 2
    width_res = DISPLAY_WIDTH / pixel_res
    height_res = DISPLAY_HEIGHT / pixel_res
    when ODIN_DEBUG {
        fmt.printfln("hires %d, %d", width_res, height_res)
    }
}

display_lores :: proc() {
    pixel_res = PIXEL_SCALE
    width_res = DISPLAY_WIDTH / pixel_res
    height_res = DISPLAY_HEIGHT / pixel_res
    when ODIN_DEBUG {
        fmt.printfln("lores %d, %d", width_res, height_res)
    }
}

display_render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK) 

    for p, i in vm.display {
        x := (i32(i) % width_res) * pixel_res
        y := (i32(i) / width_res) * pixel_res
        if bool(p) do rl.DrawRectangle(x, y, pixel_res, pixel_res, rl.WHITE)
    }
    vm.wait = false
}

scroll_pixels :: proc(scroll: i32, dir: ScrollDir) {
    x, y: i32
    switch dir {
    case .Down:
        for y = height_res - scroll - 1; y >= 0 ; y -= 1 {
            for x = 0; x < width_res; x += 1 {
                vm.display[(y+scroll)*width_res + x] = vm.display[y*width_res + x]
            }
        }
        for y = 0; y < scroll; y += 1 {
            for x = 0; x < width_res; x += 1 do vm.display[y*width_res + x] = 0
        }

    case .Right:
        for y = 0; y < height_res ; y += 1 {
            for x = width_res - scroll - 1; x >= 0; x -= 1 {
                vm.display[y*width_res + (x+scroll)] = vm.display[y*width_res + x]
            }
        }

    case .Left:
        for y = 0; y < height_res ; y += 1 {
            for x = 0; x < width_res - scroll - 1; x += 1 {
                vm.display[y*width_res + x] = vm.display[y*width_res + (x+scroll)]
            }
        }
    case .Up:
        return
    }
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
                fmt.printfln("pixel %x, %x set to %x", pos_x, pos_y, display[pos_d])
            }
        }
    }
    return flag
}

get_pixels :: proc(pixels: []byte, value: byte) {
    for i in 0..=7 do if bool(value & (0x80 >> u8(i))) do pixels[i] = 0xff 
}

set_pixel :: proc(index: u16, pixel: byte) -> (flag: byte) {
    flag = vm.display[index] != 0 ? 1: 0 
    vm.display[index] ~= pixel
    return
}
