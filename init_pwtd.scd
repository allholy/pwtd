//Written by Panagiota Anastasopoulou
//21-05-13
//PLay with the dust //startup code

ServerBoot.removeAll;

//bus
ServerTree.removeAll;
s.newBusAllocators;
~rvBus = Bus.audio(s, 2);
~makeNodes = {
	s.bind({
		~fxGroup = Group.new;
		~rv = Synth(\reverb, [\in, ~rvBus], ~fxGroup);
	});
};

//tempo
t.stop;
t = TempoClock.new(72/60).permanent_(true);

s.waitForBoot({

	s.freeAll;

	//buffers
	Buffer.freeAll;
	~bufPath = PathName.new(thisProcess.nowExecutingPath).parentPath ++ "sounds/";
	b = PathName.new(~bufPath).makeBufDict;
	//alloc
	a = Buffer.alloc(s,1024); //for freeze

	s.sync;

	//synths

	//to 140char (transformed)
	SynthDef(\klik, {
		var sig, env;
		sig = Ringz.ar(
			Impulse.ar(
				[\impfreq1.ar(2.5), 1, \impfreq3.ar(2.5)], //freq1:0.7-8 freq3:2-6
				[0.1, 0.2, 0.25]
			),
			\freq.ar(1),
			\dec.kr(1)
		);
		env = Env([0.7,1,1,0], [2,7,5] ).kr(doneAction:2);
		sig = Splay.ar(sig * env * \amp.ar(0.6));
		Out.ar(\out.ir(0), sig);
		Out.ar(\outfx.ir(0), sig *\ampfx.ar(0.8));
	}).add;

	// inspired by Fredrik Olofsson //crashes rarely (??)
	SynthDef(\ambient, {
		var a, env, sig;
		a = LFNoise2.kr(1/(9..17));
		env = EnvGate.new(1/60, fadeTime:5, doneAction:2);
		sig = BPF.ar(
			Dust2.ar(a.abs*1e4),
			a.exprange(99,1e4),1.1-a);
		sig = Ringz.ar(sig, (9..1)*99,a+1.1,a);
		sig = Splay.ar(sig * env * \amp.ar(1/20), center:\pan.kr(0) );
		Out.ar(\out.ir(0), sig);
		Out.ar(\outfx.ir(0), sig *\ampfx.ar(0.1));
	}).add;

	SynthDef(\short, {
		var sig, env;
		env = Env([0,1,1,0],[\atk.kr(0.001),\sus.kr(0.2),\rel.kr(0.07)],[\c1.kr(1),0,\c2.kr(-1)]).kr(2);
		sig = PlayBuf.ar(1, \buf.ar(0), \rate.kr(1), startPos:\spos.kr(0));
		sig = sig * env;
		sig = Pan2.ar(sig, \pan.ar(0), \amp.ar(1));
		Out.ar(\out.ir(0), sig);
		Out.ar(\outfx.ir(0), sig *\ampfx.ar(0.1));
	}).add;

	SynthDef(\pvfreeze, {
		arg soundBufnum =0;
		var sig;
		sig = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum) *\rate.kr(1), Dust.kr(\jump.kr(0.3)), Line.ar(1, 4392000, BufDur.kr(soundBufnum)*0.6), loop: 1); //hardcoded
		sig = FFT(\bufnum.kr(0), sig);
		sig = PV_Freeze(sig, \gatef.kr(0) > 0.7 );
		sig = IFFT(sig);
		sig = sig * EnvGate.new; //for fade out (?)
		Out.ar(\out.ir(0), sig!2 *\amp.ar(0.5));
		Out.ar(\outfx.ir(0), sig!2 *\ampfx.ar(0.9));
	}).add;

	SynthDef(\grains, {
		arg bufnum=0;
		var sig, trate, dur;
		trate = \t.kr(7);
		dur = 1.2 / trate;
		sig = TGrains.ar(
			2,
			Impulse.ar(trate),
			bufnum,
			1.2 ** WhiteNoise.kr(3).round(1),
			\pos.kr(1000), //Rand(0,BufDur.kr(buf)-1),
			dur,
			WhiteNoise.kr(0.45),
			1 //amp
		);
		Out.ar(\out.ir(0), sig * \amp.ar(0.7));
		Out.ar(\outfx.ir(0), sig *\ampfx.ar(0.1));
	}).add;

	SynthDef(\drop, {
		var sig, env, freq;
		sig = SinOsc.ar(\freq.ar(200));
		env = Env.perc(0.003,0.1).kr(doneAction:2); //gate?
		sig = sig * env * \amp.ar(0.6);
		Out.ar(\out.ir(0), sig!2);
		Out.ar(\outfx.ir(0), sig *\ampfx.ar(0.1));
	}).add;

	// by Nathan Ho aka Snappiz
	SynthDef(\kalimba, {
		arg mix = 0.1;
		var sig;
		sig = SinOsc.ar(\freq.ar(440)) * Env.perc(0.005, Rand(\relMin.ar(2.5), \relMax.ar(3.5)), 1, -8).kr(2);
		sig = (sig * (1 - mix)) + (DynKlank.ar(`[ 	//bank of resonators
			[240*ExpRand(0.9, 1.1), 2020*ExpRand(0.9, 1.1), 3150*ExpRand(0.9, 1.1)],
			[-4, 0, 3].dbamp,
			[0.8, 0.05, 0.07]
		], PinkNoise.ar * Env.perc(0.001, 0.01).kr(0)) * mix); //enveloped pink noise
		Out.ar(\out.ir(0), Pan2.ar(sig, \pan.kr(0), \amp.ar(0.15)));
		Out.ar(\outfx.ir(0), Pan2.ar(sig, \panfx.kr(0), \ampfx.ar(0.15)));
	}).add;

	SynthDef.new(\pink, {
		var sig ,env;
		sig = PinkNoise.ar(0.25);
		// env = Env([0.1,\a.kr(0.4),0.1],[1,2],[1,\relc.kr(-1)]).kr(2,gate:1);
		env = Env([0.1,LFNoise1.kr(0.5!2).range(0.2,1),0.1],[1,2],[1,\relc.kr(-1)]).kr(2,gate:1);
		// sig = Splay.ar(sig * env, \pan.kr(0));
		sig = sig *env * \amp.kr(0.5);
		Out.ar(\out.ir(0), sig);
	}).add;

	// from pink_brf
	SynthDef(\pinkdist, {
		arg sawRt = 11; //0.5
		var src=PinkNoise.ar(),
		lfo = {arg rt, rt2; LFPulse.ar(
			[rt+SinOsc.ar(rt2.rand,0,rrand(rt/2,rt*2)),rt+SinOsc.ar(rt2.rand,0,rrand(rt/2,rt*2))
		])};
		src=BRF.ar(
			src,rrand(250,15000)*(0.5+(lfo.(lfo.(1,2)*LFSaw.ar(sawRt).abs*5000,0.25)*0.5)),
			LFSaw.ar(sawRt*rrand(0.5,0.75)).abs*0.5+0.25
		);
		src = CombC.ar(
			(src * LFSaw.ar(sawRt*rrand(0.25,0.5),0,8).abs).tanh,
			0.3,0.25+LFSaw.ar([sawRt*0.95,sawRt*0.93],0,0.05).abs,
			4,
			0.5
		).tanh;
		Out.ar(\out.ir(0), src * \amp.kr(0.05) * EnvGate.new(0.01));
	}).add;

	SynthDef(\bass, {
		arg freq = 20;
		var aEnv, fEnv, sig, filt;
		aEnv = Env.asr(0, 1, 5).kr(2, \gate.kr(1)); //sustain & fadeout
		fEnv = Env.perc(0, 3).kr() *4000;
		sig = Mix([Saw.ar(freq * [1, 1.01]), Pulse.ar(freq / 2, 0.5)]);
		filt = LPF.ar(sig, fEnv + 100, aEnv);
		Out.ar(\out.ir(0), filt);
	}).add;

	SynthDef(\reverb, {
		var sig, wet;
		sig = In.ar(\in.ir(0), 2);
		sig = FreeVerb.ar(sig, mix:1, room:0.5, damp:0.75);
		sig = LPF.ar(sig, 500);
		Out.ar(\outfx.ir(0), sig); //check
	}).add;

	s.sync;

	ServerTree.add(~makeNodes);
	ServerTree.run;

	s.sync;
	"ready to start".postln;
});



//---------------------structure

//structure with patterns
~count = 0;

~structure = [
	{ //1
		~ambient = Synth(\ambient, [\fadeTime, 10, \amp, 1/35]);

		// ~klikfx=3;
		~klik = Pbindef(\pklik,
			\instrument, \klik,
			\dur, Pseq([9,4,2], inf),
			\impfreq1, Pwhite(0.7,9),
			\impfreq3, Pwhite(2,4),
			\freq, Pwrand( [1,100,750], [0.6,0.2,0.4], inf),
			\dec, Pwhite(0.3,2),
			\out, 0,
			\amp, Pkey(\freq).linlin(1,750,0.25,0.085),
			\outfx, ~rvBus,
			\ampfx, 3,
		).play(t);
	},

	{ //2
		~mel10 = Pbindef(\mel,
			\instrument, \kalimba, // pile up at nodetree?
			\stepsPerOctave, 10,
			\dur, 1/12 + 1/2 + 1.5*Pseq([1/3], 3) ++ Pwrand([Pseq([1/6], 6), Pseq([1/3], 4)], [0.77,0.4].normalizeSum , inf),
			\degree, Pseq([0, -3, [11, 1], 2, 4, -6, -2, [0,2,4,6,8], 2, Rest(), 0, -2, 1]-12, inf),
			\detune, Pbrown(-13, 33, 21),
			\mix, 0.2, //Pwhite(0.05, 0.2),
			\amp, Pwhite(0.06,0.1)/2.2,
		).play(t,quant:3);

	},

	{ //3
		~glitch = Pbindef(\glitch,
			\instrument, \short,
			\dur, Pwrand([Pseq([1/6],9),Pseq([1/3],3), Pseq([1/9],6)], [0.85,0.15,0.5].normalizeSum,inf),
			\buf, Prand(b[\short],inf),
			\pan, Pwrand([Pseq([0],9),Pseq([-1,1,0],3),Pwhite(-1.0,1.0,9)], [0.75,0.1,0.15],inf),
			\sus, Pgauss(0.06,0.02,inf),
			\rel, 0.09,
			\spos, Pexprand(10,500)-1,
			\rate, Pwrand([1, Pwhite(2.1,3,1), Pwhite(0.5,0.9,1)],[0.88,0.1,0.02], inf),
			\out, 0,
			\amp, Pseq([Pexprand(0.5,1,1),Pexprand(0.07,0.49,2)],inf) *1.1,
			\outfx, ~rvBus,
			\ampfx, 2,
		).play(t,quant:3);
	},

	{ //4
		~ambient.release;

		~fr = Synth(\pvfreeze, [
			\bufnum, a.bufnum,
			\soundBufnum, b[\other][1].bufnum,
			\rate, rrand(0.95,1.1),
			\jump, 0.1,
			\amp, 0.3,
			\out, 0,
			\outfx, ~rvBus,
			\ampfx, 0.3,
		]);
	},

	{ //5
		~pink = Pbindef(\wave,
			\instrument, \pink,
			\dur, 3,
			\relc, Pwhite(-4,4),
			\amp, 0.4
		).play(t);

		~mel10.stop;
	},


	{ //6
		~pinkdist = Synth(\pinkdist, [\amp, 0.055, \fadeTime, 2.4]);
	},

	{ //7
		Pbindef(\glitch, \dur, Pwhite(1/30,1/3, inf));

		~fr.set(\jump, 3, \amp, 0.15);

		~pinkdist.set(\sawRt,8.1, \amp, 0.08);
		// ~pink.release;
		Pbindef(\wave).stop();

		~klik.stop;

		~grains = Synth(\grains, [
			\buf, b[\other][0].bufnum,
			\out, 0,
			\amp, 1,
			\outfx, ~rvBus,
			\ampfx, 0.35
		]);
	},

	{ //8
		~bass = Synth(\bass);
		~pinkdist.release;

		Pbindef(\wave, \amp, 0.15).play(quant:1);
	},

	{ //9
		~grains.set(\t, 6, \pos, 30000, \amp, 0.8);

		~bass.set(\gate, 0);

		~fr.release;

		Pbindef(\glitch).stop();
	},

	{ //10
		~grains.free;
	},

	{ //11
		Pbindef(\wave).stop;
		//freeAll (in case something is still here)
		s.defaultGroup.set(\gate, 0, \fadeTime, 4);
		Pbindef.all.do(_.stop);
	}
];

"structure ready".postln; ":)";

/*
//credits
a few sounds from Freesound,
one sound from "The Conet Project",
method: https://gist.github.com/elifieldsteel/396cd1326d3c981ba1fd2a3c47d90ea3.js (Eli Fieldsteel)
/*
