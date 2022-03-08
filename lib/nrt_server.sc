// sclang render.scd
(
var mainServer = Server(\Local2, NetAddr("127.0.0.1", 57112));
var server = Server(\nrt, NetAddr("127.0.0.1", 57114), options:ServerOptions.new.numOutputBusChannels_(2));
var score;
SynthDef("lpf_rampup", {
	arg out=0,  dur=30;
	var duration=BufDur.ir(0);
	var snd = PlayBuf.ar(2,0,loop: 0.0,doneAction:0);
	snd=LPF.ar(snd,XLine.kr(100,20000,duration));
	snd = snd * EnvGen.ar(Env.new([0, 1, 1, 0], [0,dur,0]), doneAction:2);
	Out.ar(out, snd);
}).load(server);
SynthDef("lpf_rampdown", {
	arg out=0,  dur=30;
	var duration=BufDur.ir(0);
	var snd = PlayBuf.ar(2,0,loop: 0.0,doneAction:0);
	snd=LPF.ar(snd,XLine.kr(20000,100,duration));
	snd = snd * EnvGen.ar(Env.new([0, 1, 1, 0], [0,dur,0]), doneAction:2);
	Out.ar(out, snd);
}).load(server);
SynthDef("dec_ramp", {
	arg out=0,  dur=30;
	var duration=BufDur.ir(0);
	var snd = PlayBuf.ar(2,0,loop: 0.0,doneAction:0);
	snd=SelectX.ar(Line.kr(0,1,duration/4),[snd,Decimator.ar(snd,8000,8)]);
	snd = snd * EnvGen.ar(Env.new([0, 1, 1, 0], [0,dur,0]), doneAction:2);
	Out.ar(out, snd);
}).load(server);
SynthDef("dec", {
	arg out=0,  dur=30;
	var duration=BufDur.ir(0);
	var snd = PlayBuf.ar(2,0,loop: 0.0,doneAction:0);
	snd=Decimator.ar(snd,8000,8);
	snd = snd * EnvGen.ar(Env.new([0, 1, 1, 0], [0,dur,0]), doneAction:2);
	Out.ar(out, snd);
}).load(server);
SynthDef("reverberate", {
	arg out=0,  dur=30;
	var duration=BufDur.ir(0);
	var snd = PlayBuf.ar(2,0,loop: 0.0,doneAction:0);
	snd=Greyhole.ar(snd);
	snd=LeakDC.ar(snd);
	snd = snd * EnvGen.ar(Env.new([0, 1, 1, 0], [0,dur,0]), doneAction:2);
	Out.ar(out, snd);
}).load(server);

score={
	arg inFile,outFile,synthDefinition,durationScaling,oscCallbackPort;
	Buffer.read(mainServer,inFile,action:{
		arg buf;
		Routine {
			var buffer;
			var score;
			var duration=buf.duration*durationScaling;

			"defining score".postln;
			score = [
				[0.0, ['/s_new', synthDefinition, 1000, 0, 0,  \dur,duration]],
				[0.0, ['/b_allocRead', 0, inFile]],
				[duration, [\c_set, 0, 0]] // dummy to end
			];

			"recording score".postln;
			Score(score).recordNRT(
				outputFilePath: outFile,
				sampleRate: 48000,
				headerFormat: "wav",
				sampleFormat: "int24",
				options: server.options,
				duration: duration,
				action: {
					postln("done rendering: " ++ outFile);
					NetAddr.new("localhost",oscCallbackPort).sendMsg("/quit");
					postln("sent quit")
				}
			);

		}.play;
	});
};
mainServer.waitForBoot({
	var oscExit = OSCFunc({ arg msg, time, addr, recvPort; [msg, time, addr, recvPort].postln; server.free; mainServer.free; 0.exit; }, '/quit',recvPort:57113);
	var oscScore = OSCFunc({ arg msg, time, addr, recvPort;
		var inFile=msg[1].asString;
		var outFile=msg[2].asString;
		var synthDefinition=msg[3].asSymbol;
		var durationScaling=msg[4].asFloat;
		var oscCallbackPort=msg[5].asInteger;
		[msg, time, addr, recvPort].postln;
		score.value(inFile,outFile,synthDefinition,durationScaling,oscCallbackPort);
		"finished".postln;
	}, '/score',recvPort:57113);

	// var outfile=thisProcess.nowExecutingPath.dirname++"/out.wav";
	// var inFile=thisProcess.nowExecutingPath.dirname++"/in.wav";

});
)
