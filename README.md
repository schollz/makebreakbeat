# makebreakbeat

make break beats

![img](https://user-images.githubusercontent.com/6550035/156637615-a0363244-2186-4604-b75f-4c1936982e24.png)

this script is a wrapper for another script I wrote that generates breakbeats with [sox](http://sox.sourceforge.net/) and [aubio](https://aubio.org/). the purpose is to generate breakbeats but you can use it to mangle all sorts of audio.

# Requirements

- norns

# Documentation

- press K2 to generate beat
- press K3 to toggle playing

the beats that are made are automatically put into the `~/dust/audio/makebreakbeat` folder and named according to the current tempo.

this script splits the input file by onset markers and then iterates through each slice and manipulates the slice with effects with some probability. all the effect probabilities are available to modify in the parameters.

- deviation: probability of deviating from base pattern (0-100%)
- reverse: probability of reversing
- stutter: probability of stutter
- pitch: probability of pitch up
- trunc: probability of truncation
- half: probability of slow down
- reverb: probability of adding reverb tail to kick/snare
- stretch: probability of stretching audio
- kick: probability of snapping a kick to down beat
- snare: probability of snapping a snare to down beat
- kick db:  volume of added kick in dB
- snare db:  volume of added snare in dB

# Install

install with

```
;install https://github.com/schollz/makebreakbeat
```

once you start the script for the first time it will install `aubio` and `sox` (~5 MB total).