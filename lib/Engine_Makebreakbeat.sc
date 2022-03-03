// Engine_Makebreakbeat

// Inherit methods from CroneEngine
Engine_Makebreakbeat : CroneEngine {

    // Makebreakbeat specific v0.1.0
    var sampleBuffMakebreakbeat;
    var playerMakebreakbeat;
    var params;
    // Makebreakbeat ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    alloc {
        // Makebreakbeat specific v0.0.1

        // two players per buffer (4 players total)
        SynthDef("playerMakebreakbeat",{ 
            arg out=0, bufnum=0, rate=1, start=0, end=1, t_trig=0,
            loops=1000000,amp=1,lpf=18000,lpfqr=1.0;
            var sndfinal,snd,snd2,pos,pos2,frames,duration,env;
            var startA,endA,startB,endB,crossfade,aOrB;

            // latch to change trigger between the two
            aOrB=ToggleFF.kr(t_trig);
            startA=Latch.kr(start,aOrB);
            endA=Latch.kr(end,aOrB);
            startB=Latch.kr(start,1-aOrB);
            endB=Latch.kr(end,1-aOrB);
            crossfade=Lag.ar(K2A.ar(aOrB),0.05);

            rate = rate*BufRateScale.kr(bufnum);
            frames = BufFrames.kr(bufnum);

            pos=Phasor.ar(
                trig:aOrB,
                rate:rate,
                start:(((rate>0)*startA)+((rate<0)*endA))*frames,
                end:(((rate>0)*endA)+((rate<0)*startA))*frames,
                resetPos:(((rate>0)*startA)+((rate<0)*endA))*frames,
            );
            snd=BufRd.ar(
                numChannels:2,
                bufnum:bufnum,
                phase:pos,
                interpolation:4,
            );

            // add a second reader
            pos2=Phasor.ar(
                trig:(1-aOrB),
                rate:rate,
                start:(((rate>0)*startB)+((rate<0)*endB))*frames,
                end:(((rate>0)*endB)+((rate<0)*startB))*frames,
                resetPos:(((rate>0)*startB)+((rate<0)*endB))*frames,
            );
            snd2=BufRd.ar(
                numChannels:2,
                bufnum:bufnum,
                phase:pos2,
                interpolation:4,
            );

            sndfinal=(crossfade*snd)+((1-crossfade)*snd2) * Lag.kr(amp);

            sndfinal=RLPF.ar(sndfinal,Lag.kr(lpf),Lag.kr(lpfqr));

            Out.ar(out,sndfinal);
        }).add; 

        this.addCommand("load_track","s", { arg msg;
            Buffer.read(Server.default, msg[1],action:{ arg buf;
                buf.postln;
                if (playerMakebreakbeat.notNil,{
                    playerMakebreakbeat.set(\bufnum,buf.bufnum);
                },{
                    playerMakebreakbeat=Synth("playerMakebreakbeat",[\bufnum,buf.bufnum,\t_trig,1])
                })
            }); 
        });

        this.addCommand("tozero","", { arg msg;
            if (playerMakebreakbeat.notNil,{
                playerMakebreakbeat.set(\t_trig,1);
            });
        });

        params = Dictionary.newFrom([
            \amp, 1,
            \lpf, 18000,
            \lpfqr, 1,
        ]);

        params.keysDo({ arg key;
            this.addCommand(key, "f", { arg msg;
                if (playerMakebreakbeat.notNil,{
                    playerMakebreakbeat.set(key,msg[1]);
                });
            });
        });

        // ^ Makebreakbeat specific

    }

    free {
        // Makebreakbeat Specific v0.0.1
        playerMakebreakbeat.free;
        sampleBuffMakebreakbeat.free;
        // ^ Makebreakbeat specific
    }
}
