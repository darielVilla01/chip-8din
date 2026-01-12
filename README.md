# Chip-8din
Simple chip8 interpreter written in Odin and using Raylib

## Usage
```
./chip8din
Usage: chip8din [OPTIONS...] rom_file

Options:
-set-fps frames         Set the frames per second of the display (default: 60)
-set-ipf instructions   Set the instructions per frame of the virtual machine (default: 60)
-help                   Show this help message
```

## Tests
The Timendus's test suite is included as a git submodule. Run:
`git submodule init && git submodule update`
to clone the submodule repository
