package chip_8din

import rl "vendor:raylib"

import "core:math"
import "core:c"

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

sound_init :: proc() {
    rl.InitAudioDevice()
    rl.SetAudioStreamBufferSizeDefault(MAX_SAMPLES_PER_UPDATE)
    stream = rl.LoadAudioStream(42100, 16, 1)
    rl.SetAudioStreamCallback(stream, AudioInputCallback)
}

sound_play :: proc() {
    if rl.IsAudioStreamPlaying(stream) && vm.sound <= 1 do rl.StopAudioStream(stream)
    if !rl.IsAudioStreamPlaying(stream) && vm.sound > 1 do rl.PlayAudioStream(stream)
}

sound_deinit :: proc() {
    rl.UnloadAudioStream(stream)
}
