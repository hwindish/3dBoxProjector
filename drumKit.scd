s.boot;

(

SynthDef(\kick, { |out=0, amp=0.8, freq=60|
    var env = Env.perc(0.01, 0.3).kr(doneAction:2);
    var osc = SinOsc.ar(freq * Env.perc(0.001, 0.2).kr.range(1, 0.5));
    Out.ar(out, osc * env * amp);
}).add;

SynthDef(\snare, { |out=0, amp=0.8, pitch=300|
    var noise = WhiteNoise.ar * Env.perc(0.005, 0.2).kr(doneAction:2);
    var tone = SinOsc.ar(pitch) * Env.perc(0.005, 0.1).kr;
    var sig = (noise * 0.6 + tone * 0.4) * amp;
    Out.ar(out, sig ! 2);
}).add;

SynthDef(\hihat, { |out=0, amp=0.8, pitch=5000|
    var env = Env.perc(0.001, 0.1).kr(doneAction:2);
    var noise = WhiteNoise.ar;
    var filtered = BPF.ar(noise, pitch, 0.3);
    Out.ar(out, filtered * env * amp);
}).add;

SynthDef(\tom, { |out=0, amp=0.8, freq=150|
    var env = Env.perc(0.01, 0.4).kr(doneAction:2);
    var pitchEnv = Env.perc(0.005, 0.2).kr.range(1.5, 0.8);
    var osc = SinOsc.ar(freq * pitchEnv) * env;
    var body = osc + (SinOsc.ar(freq * 0.5) * env * 0.3); // extra low-end body
    Out.ar(out, body * amp);
}).add;

SynthDef(\clap, { |out=0, amp=0.8|
    var env = Env([0, 1, 0.8, 0.6, 0], [0.005, 0.02, 0.03, 0.05], 'linear').kr(doneAction:2);
    var noise = WhiteNoise.ar;
    var filtered = BPF.ar(noise, 2000, 0.5); // band-pass to shape it
    var burst = Mix.fill(3, { DelayC.ar(filtered, 0.02, Rand(0.005, 0.02)) }) * env;
    Out.ar(out, burst * amp ! 2);
}).add;
)

(

//var port = 57120;
//var udpServer = NetAddr.langPort(port);

OSCdef(\drumTrigger, { |msg, time, addr|
    var index = msg[1];
    var vol = msg[2].clip(0.0, 1.0);
	var pitch = msg[3].linexp(0,360,20,10000); // Hz or base freq depending on synth

    case
    { index == 0 } { Synth(\kick, [\amp, vol, \freq, pitch]) }
    { index == 1 } { Synth(\snare, [\amp, vol, \pitch, pitch]) }
    { index == 2 } { Synth(\hihat, [\amp, vol, \pitch, pitch]) }
	{ index == 3 } { Synth(\tom, [\amp, vol, \pitch, pitch]) }
    { index == 4 } { Synth(\clap, [\amp, vol, \pitch, pitch]) }
    { true } { "Unknown drum index: %".format(index).warn };

	"received Message".postln

}, '/drum');
)

n = NetAddr.localAddr; // sends to self
n.sendMsg('/drum', 0, 1, 300)
	
);

