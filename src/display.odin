package chip_8din

import rl "vendor:raylib"

import "core:fmt"
import "core:c"

PIXEL_SCALE :: 16
DISPLAY_WIDTH :: 0x40 * PIXEL_SCALE
DISPLAY_HEIGHT :: 0x20 * PIXEL_SCALE

ScrollDir :: enum {Left, Right, Up, Down}

@(private="file")
pixel_res, width_res, height_res: i32

display_init :: proc(fps: int) {
    rl.InitWindow(DISPLAY_WIDTH, DISPLAY_HEIGHT, "chip-8din")
    rl.SetTargetFPS(c.int(fps))
    display_lores()
}

display_deinit :: proc() {
    rl.CloseAudioDevice()
    rl.CloseWindow()
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
    pixels: [16]byte
    big_sprite := len(sprite) > 16
    inc, sprite_width := 1, 8
    
    if big_sprite do inc, sprite_width = 2, 16
    for i := 0; i < len(sprite); i += inc {
        get_pixels(pixels[:8], sprite[i])
        if big_sprite do get_pixels(pixels[8:], sprite[i+1])

        if vm.variant != .XO && y < cast(u8)height_res && y + u8(i) >= cast(u8)height_res do break
        for j in 0..<sprite_width {
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
    for i in 0..=7 do pixels[i] = bool(value & (0x80 >> u8(i))) ? 0xff: 0
}

set_pixel :: proc(index: u16, pixel: byte) -> (flag: byte) {
    flag = vm.display[index] != 0 ? 1: 0 
    vm.display[index] ~= pixel
    return
}
