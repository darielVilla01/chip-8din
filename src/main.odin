package chip_8din

import "core:fmt"

main :: proc() {
    config := vm_configuration()
    if config == (VM_Config{}) do return

    chip8_init(config.file_path)
    
    if !pc_is_valid() do return

    cycles := 0
    display_init(config.fps)
    for pc_is_valid() && display_running() {
        if !vm.wait {
            opcode := fetch_instruction()
            when ODIN_DEBUG {
                fmt.printfln("pc %x, opcode: %X, v-regs %x, I-reg %x, delay %d, sound %d",
                    vm.pc, opcode, vm.v, vm.i, vm.delay, vm.sound)
            }
            execute_instruction(opcode)
        }

        cycles += 1

        if cycles % 60 == 0 do decrement_timers()
        if cycles % config.ipf == 0 { 
            display_render()
            display_sound()
        }
    }
    display_deinit()
}
