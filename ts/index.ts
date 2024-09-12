type EngineMessage = {
  tag: string,
  message: string,
}

type EngineState = {
  delay: { time: number, feedback: number },
  melody: number[][],
  envelope: {
    attack: number,
    decay: number,
    sustain: number,
    release: number,
  },
  lfo: {
    frequency: number,
    intensity: number,
    wave: OscillatorType,
  },
  oscillator: {
    waveform: OscillatorType,
    coarseFrequency: number,
    fineFrequency: number,
    octave: number,
  }
}

export class AudioPlayer {
  private viewUpdateCallback: Function;
  private audioCtx?: AudioContext;

  private bpm: number;
  private currentChord;
  private playing: boolean;

  private drumPatterns: Map<string, boolean[]>
  private intervalIds: any[];
  private state: EngineState;
  constructor(viewUpdateCallback: Function) {
    this.state = {
      delay: { time: 0.9, feedback: 0 },
      melody: [[], [], [], [], [], [], [], []],
      envelope: {
        attack: 0,
        decay: 0.1,
        sustain: 0.4,
        release: 0.2,
      },
      lfo: {
        frequency: 10,
        intensity: 9,
        wave: 'sine'
      },
      oscillator: {
        waveform: 'sine',
        coarseFrequency: 0,
        fineFrequency: 0,
        octave: 0,
      }
    };

    this.viewUpdateCallback = viewUpdateCallback;

    this.currentChord = 0;
    this.playing = false;
    this.bpm = 300;

    this.drumPatterns = new Map([
      ["kick", Array(16).fill(false)],
      ["hihat", Array(16).fill(false)],
      ["snare", Array(16).fill(false)],
    ]);

    this.intervalIds = [];
    this.audioCtx!;
  }

  private playKick(currentChordNumber: number) {
    const kickGain = this.audioCtx!.createGain();
    kickGain.gain.setValueAtTime(1, this.audioCtx!.currentTime);
    kickGain.connect(this.audioCtx!.destination);
    kickGain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx!.currentTime + 0.5);

    const oscillator = this.audioCtx!.createOscillator();
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(150, this.audioCtx!.currentTime);
    oscillator.connect(kickGain)
    oscillator.frequency.exponentialRampToValueAtTime(0.01, this.audioCtx!.currentTime + 0.5);

    oscillator.start(currentChordNumber * (60000 / this.bpm) / 1000);
    oscillator.stop((currentChordNumber * (60000 / this.bpm) / 1000) + 0.2);
  }

  private playSnare(currentChordNumber: number) {
    const bufferSize = this.audioCtx!.sampleRate * 0.2;
    const buffer = this.audioCtx!.createBuffer(1, bufferSize, this.audioCtx!.sampleRate);
    const output = buffer.getChannelData(0);

    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }

    const source = this.audioCtx!.createBufferSource();
    source.buffer = buffer;

    const snareGain = this.audioCtx!.createGain();
    snareGain.gain.setValueAtTime(1, this.audioCtx!.currentTime);
    snareGain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx!.currentTime + 0.2);

    source.connect(snareGain);
    snareGain.connect(this.audioCtx!.destination);
    source.start(currentChordNumber * (60000 / this.bpm) / 1000);
  }

  private playHihat(currentChordNumber: number) {
    const bufferSize = this.audioCtx!.sampleRate * 0.1;
    const buffer = this.audioCtx!.createBuffer(1, bufferSize, this.audioCtx!.sampleRate);
    const output = buffer.getChannelData(0);

    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }

    const source = this.audioCtx!.createBufferSource();
    source.buffer = buffer;

    const hihatGain = this.audioCtx!.createGain();
    hihatGain.gain.setValueAtTime(1, this.audioCtx!.currentTime);
    hihatGain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx!.currentTime + 0.1);

    source.connect(hihatGain);
    hihatGain.connect(this.audioCtx!.destination);
    source.start(currentChordNumber * (60000 / this.bpm) / 1000);
  }

  private invokeInterval(currentChordNumberStart: number) {
    const lookahead = 75;
    const interval = 50;

    let currentChordNumber = currentChordNumberStart;

    while (this.playing && currentChordNumber * (60000 / this.bpm) < (this.audioCtx!.currentTime * 1000) + lookahead) {
      let chord: number[] = this.state.melody[currentChordNumber % 8];
      chord.forEach((frequency) => {
        const gainNode = this.audioCtx!.createGain();
        const startTime = currentChordNumber * (60000 / this.bpm) / 1000;
        gainNode.gain.setValueAtTime(0, startTime);
        gainNode.gain.linearRampToValueAtTime(0.8, startTime + this.state.envelope.attack);
        gainNode.gain.linearRampToValueAtTime(this.state.envelope.sustain * 0.8, startTime + this.state.envelope.attack + this.state.envelope.decay);
        gainNode.gain.setValueAtTime(this.state.envelope.sustain * 0.8, startTime + 0.2 - this.state.envelope.release);
        gainNode.gain.linearRampToValueAtTime(0, startTime + 0.2);
        gainNode.connect(this.audioCtx!.destination);

        const oscillator = this.audioCtx!.createOscillator();
        oscillator.type = this.state.oscillator.waveform;
        //oscillator.frequency.setValueAtTime(frequency * 2 ** this.state.oscillator.octave, this.audioCtx!.currentTime);


        if (this.state.delay.feedback > 0) {
          const delayNode = this.audioCtx!.createDelay(1.0);
          delayNode.delayTime.setValueAtTime(this.state.delay.time, this.audioCtx!.currentTime);
          const feedbackGain = this.audioCtx!.createGain();
          feedbackGain.gain.setValueAtTime(this.state.delay.feedback, this.audioCtx!.currentTime);
          delayNode.connect(feedbackGain);
          feedbackGain.connect(delayNode);
          gainNode.connect(delayNode);
          delayNode.connect(this.audioCtx!.destination);
        }

        // Add coarse and fine frequencies to the oscillator frequency
        const baseFrequency = frequency * 2 ** this.state.oscillator.octave;
        const coarseAdjustment = this.state.oscillator.coarseFrequency;
        const fineAdjustment = this.state.oscillator.fineFrequency / 100; // Assuming fine frequency is in cents
        const adjustedFrequency = baseFrequency * (1 + coarseAdjustment + fineAdjustment);
        oscillator.frequency.setValueAtTime(adjustedFrequency, this.audioCtx!.currentTime);

        oscillator.connect(gainNode);

        const lfo = this.audioCtx!.createOscillator();
        console.log(this.state.lfo.wave);
        lfo.type = this.state.lfo.wave;
        lfo.frequency.setValueAtTime(this.state.lfo.frequency, this.audioCtx!.currentTime);

        const lfoGain = this.audioCtx!.createGain();
        lfoGain.gain.setValueAtTime(this.state.lfo.intensity, this.audioCtx!.currentTime);

        lfo.connect(lfoGain);
        lfoGain.connect(oscillator.frequency);

        oscillator.start(currentChordNumber * (60000 / this.bpm) / 1000);
        oscillator.stop((currentChordNumber * (60000 / this.bpm) / 1000) + 0.2);
        lfo.start();
      })

      if (this.drumPatterns.get("kick")![currentChordNumber % 16]) {
        this.playKick(currentChordNumber);
      }

      if (this.drumPatterns.get("snare")![currentChordNumber % 16]) {
        this.playSnare(currentChordNumber);
      }

      if (this.drumPatterns.get("hihat")![currentChordNumber % 16]) {
        this.playHihat(currentChordNumber);
      }

      this.viewUpdateCallback(currentChordNumber);
      currentChordNumber += 1;
    }

    //if (this.playing) {
    this.intervalIds.push(setTimeout(() => { this.invokeInterval(currentChordNumber) }, interval));
    //}
  }

  private clearIntervals() {
    for (let interval of this.intervalIds) {
      clearTimeout(interval);
    }
  }

  public processAudioCommand(audioCommand: string) {
    if (audioCommand === "play") {
      if (this.audioCtx === undefined) {
        this.audioCtx = new AudioContext();
      }

      if (this.audioCtx !== undefined) {
        this.audioCtx!.close();
        this.audioCtx = new AudioContext();
      }

      if (!this.playing) {
        this.playing = true;
        this.invokeInterval(this.currentChord);
      }
    } else if (audioCommand === "pause") {
      this.playing = false;
      this.clearIntervals();

      if (this.audioCtx !== undefined) {
        this.audioCtx!.close();
        this.audioCtx! = new AudioContext();
      }
    } else if (audioCommand === "reset") {
      this.playing = false;
      this.clearIntervals();
      this.currentChord = 0;

      if (this.audioCtx !== undefined) {
        this.audioCtx!.close();
        this.audioCtx! = new AudioContext();
      }
    }
  }

  public stepEngine(engineMessage: EngineMessage) {
    const { tag, message } = engineMessage;
    switch (tag) {
      case 'bpm':
        const bpm = JSON.parse(message);
        this.bpm = bpm;
        break;
      case 'delay':
        const delay = JSON.parse(message);
        switch (delay.param) {
          case 'time': this.state.delay.time = delay.value; break;
          case 'feedback': this.state.delay.feedback = delay.value; break;
        }
        break;
      case 'melody':
        const melody = JSON.parse(message);
        this.state.melody = melody;
        break;
      case 'audio_command':
        const command = JSON.parse(message);
        this.processAudioCommand(command);
        break;
      case 'envelope':
        const envelope = JSON.parse(message);
        switch (envelope.param) {
          case 'attack': this.state.envelope.attack = envelope.value; break;
          case 'decay': this.state.envelope.decay = envelope.value; break;
          case 'release': this.state.envelope.release = envelope.value; break;
          case 'sustain': this.state.envelope.sustain = envelope.value; break;
        }
        break;
      case 'oscillator':
        const oscillator = JSON.parse(message);
        console.log(oscillator);
        switch (oscillator.param) {
          case 'waveform': this.state.oscillator.waveform = oscillator.value as OscillatorType; break;
          case 'coarseFrequency': {
            console.log("coarseFrequency: " + oscillator.value);
            this.state.oscillator.coarseFrequency = oscillator.value; break;
          }
          case 'fineFrequency': this.state.oscillator.fineFrequency = oscillator.value; break;
          case 'octave': this.state.oscillator.octave = oscillator.value; break;
        }
        break;
      case 'lfo':
        const lfo = JSON.parse(message);
        console.log(message);
        switch (lfo.param) {
          case 'frequency': this.state.lfo.frequency = lfo.value; break;
          case 'intensity': this.state.lfo.intensity = lfo.value; break;
          case 'waveType': {
            this.state.lfo.wave = lfo.value as OscillatorType;
            console.log("set wave to " + this.state.lfo.wave);
          }
        }
        break;
      default:
        console.warn(`Unknown message tag: ${tag}`);
    }
  }

  public toggleDrumPatternAt(drum: string, column: number) {
    this.drumPatterns.get(drum)![column] = !this.drumPatterns.get(drum)![column];
  }

  public updateBpm(bpm: number) {
    this.bpm = bpm;
  }
}