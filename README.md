# makebreakbeat

make break beats, by building or splicing.

![img](https://user-images.githubusercontent.com/6550035/156637615-a0363244-2186-4604-b75f-4c1936982e24.png)

this script is a wrapper for [another script I wrote](https://github.com/schollz/dnb.lua/) that "breaks" a sample. you can use it to make "breakbeat" style drums or simply make glitch loops from any sample.

# Requirements

- norns

# Documentation

this script is actually *two* scripts - *makebreakbeat/bybuilding* and *makebreakbeat/bysplicing*. the name of each script corresponds to a different methods of breaking the beat. in both the controls and UI is exactly the same:

- press K2 to generate beat
- press K3 to toggle playing
- use any E to change sample

the scripts themselves are separated because it was easier.

## make breakbeats *by building*

the *bybuilding* script splits a file into pieces based on the positions of the onsets and then rebuilds the audio one piece at a time, by selecting a piece and adding effects to it and then appending it to the file.

to "break" a beat, this script first determines the tempo of the input file. it then determines onsets based on the tempo (minimum distance being sixteenth notes) and splits the input file into slices by onset markers. it then takes each slice and manipulates the slice with effects with some probability. the manipulated slice is then appended to an audio file at a position quantized to the desired tempo (set by norns clock). all the effect probabilities are available to modify in the parameters.

- [deviation](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L546-L548): probability of deviating from base pattern (0-100%)
- [reverse](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L611): probability of reversing (0-100%)
- [stutter](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L292-L330): probability of stutter (with random volume/pitch ramps) (0-100%)
- [pitch](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L595): probability of pitch up (0-100%)
- [trunc](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L333-L346): probability of truncation (0-100%)
- [half](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L603): probability of slow down (0-100%)
- [reverb](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L655): probability of adding reverb tail to kick/snare (0-100%)
- [stretch](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L281-L290): probability of stretching audio (0-100%)
- [kick](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L577): probability of snapping a kick to down beat (0-100%)
- [snare](https://github.com/schollz/makebreakbeat/blob/a81972cd0b642a5efa309b46867e8bc090bb4957/lib/dnb.lua#L586): probability of snapping a snare to down beat (0-100%)
- kick db:  volume of added kick in dB (-96-0 dB)
- snare db:  volume of added snare in dB (-96-0 dB))

all the resulting audio files are automatically put into the `~/dust/audio/makebreakbeat` folder.


## make breakbeats *by splicing*

the *bysplicing* script assumes that the input file is a loop and repeats the loop and then copies random regions, adds effects to that copy, and then pastes the effected copy to a random position along the loop. in contrast to *bybuilding*, the *bysplicing* script essentially makes the audio file in-place.

the *bysplicing* script also has some improvements to effects. I added a non-realtime SuperCollider server to it which can add more complicated effects like filter ramps, tape emulator effects etc.

this script also has the side effect of being able to run on any file, even if it doesn't have onset detection! it simply assumes a specific tempo based on the size of the loop and then repeats it until the requested number of beats is reached.



## notes

this script generates beats *slowly*. to get around this I suggest generating short beats (8-16 beats) continuously (beats continue to play when generating).

# Install

install with

```
;install https://github.com/schollz/makebreakbeat
```

once you start the script for the first time it will install `aubio` and `sox` (~5 MB total).
