package chip_8din

import "core:fmt"
import rl "vendor:raylib"

keypad := [?]rl.KeyboardKey{
    rl.KeyboardKey.X,
    rl.KeyboardKey.ONE,
    rl.KeyboardKey.TWO,
    rl.KeyboardKey.THREE,
    rl.KeyboardKey.Q,
    rl.KeyboardKey.W,
    rl.KeyboardKey.E,
    rl.KeyboardKey.A,
    rl.KeyboardKey.S,
    rl.KeyboardKey.D,
    rl.KeyboardKey.Z,
    rl.KeyboardKey.C,
    rl.KeyboardKey.FOUR,
    rl.KeyboardKey.R,
    rl.KeyboardKey.F,
    rl.KeyboardKey.V,
}

is_key_pressed :: proc(key: byte) -> bool {
    return rl.IsKeyDown(keypad[key])
}

get_keypad_input :: proc() -> (key: byte, success: bool) {
    for k: byte = 0; k < 16 && !success; k += 1 {
        key, success = k, rl.IsKeyReleased(keypad[k])
    }
    return
}
