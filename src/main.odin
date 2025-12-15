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
        opcode := fetch_instruction()
        fmt.printfln("opcode: %X, v-regs %x, I-reg %x, pc %x, cycles %d",
            opcode, vm.v, vm.i, vm.pc, cycles)
        execute_instruction(opcode)

        display_render()
        cycles += 1
    }
    display_deinit()
}
