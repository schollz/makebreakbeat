# makebreakbeat

make break beats.

![img](https://user-images.githubusercontent.com/6550035/156637615-a0363244-2186-4604-b75f-4c1936982e24.png)

this script is a wrapper for [another script I wrote](https://github.com/schollz/dnb.lua/) that generates breakbeats with [sox](http://sox.sourceforge.net/) and [aubio](https://aubio.org/). the purpose is to generate and play breakbeats but you can use it to mangle all sorts of audio.

# Requirements

- norns

# Documentation

- press K2 to generate beat
- press K3 to toggle playing

to "break" a beat, this script first determines the tempo of the input file. it then determines onsets based on the tempo (minimum distance being sixteenth notes) and splits the input file into slices by onset markers. it then takes each slice and manipulates the slice with effects with some probability. the manipulated slice is then appended to an audio file at a position quantized to the desired tempo (set by norns clock). all the effect probabilities are available to modify in the parameters.

- deviation: probability of deviating from base pattern (0-100%)
- reverse: probability of reversing (0-100%)
- stutter: probability of stutter (with random volume/pitch ramps) (0-100%)
- pitch: probability of pitch up (0-100%)
- trunc: probability of truncation (0-100%)
- half: probability of slow down (0-100%)
- reverb: probability of adding reverb tail to kick/snare (0-100%)
- stretch: probability of stretching audio (0-100%)
- kick: probability of snapping a kick to down beat (0-100%)
- snare: probability of snapping a snare to down beat (0-100%)
- kick db:  volume of added kick in dB (-96-0 dB)
- snare db:  volume of added snare in dB (-96-0 dB))

all the resulting audio files are automatically put into the `~/dust/audio/makebreakbeat` folder.

## notes

this script generates beats *slowly*. to get around this I suggest generating short beats (8-16 beats) continuously (beats continue to play when generating).

# Install

install with

```
;install https://github.com/schollz/makebreakbeat
```

once you start the script for the first time it will install `aubio` and `sox` (~5 MB total).