package chip_8din

import "core:os"
import "core:fmt"

main :: proc() {
    if len(os.args) < 2 {
        fmt.println("No file provided")
        return
    }

    chip8_init(os.args[1])
    
    if !check_bounds() do return

    fmt.println("File loaded successfully")

    cycles := 0
    display_init()
    for check_bounds() && !display_running() {
        opcode: u16
        if !vm.wait {
            opcode = fetch_instruction()
            execute_instruction(opcode)
        }

        cycles += 1
        fmt.printfln("opcode: %X, v-regs %x, I-reg %x, delay %d, pc %x",
            opcode, vm.v, vm.i, vm.delay, vm.pc)

        if cycles % 60 == 0 {
            display_render()
            decrement_timers()
        }
    }
    display_deinit()
}
