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

  private wave: any = "sine";

  private lfoFrequency: number;
  private lfoIntensity: number;

  private octave: number;
  private state: EngineState;

  constructor(viewUpdateCallback: Function) {
    this.state = {
      delay: { time: 0.9, feedback: 0 },
      melody: [[], [], [], [], [], [], [], []],
      envelope: {
        attack: 0,
        decay: 0.1,
        sustain: 0.02,
        release: 0.001
      }
    };

    this.viewUpdateCallback = viewUpdateCallback;

    this.currentChord = 0;
    this.playing = false;
    this.bpm = 200;

    this.lfoFrequency = 10;
    this.lfoIntensity = 9;

    this.octave = 0;

    this.drumPatterns = new Map([
      ["kick", Array(16).fill(false)],
      ["hihat", Array(16).fill(false)],
      ["snare", Array(16).fill(false)],
    ]);

    this.intervalIds = [];
    this.audioCtx!;
  }

  private playKick() {
    const kickGain = this.audioCtx!.createGain();
    kickGain.gain.setValueAtTime(1, this.audioCtx!.currentTime);
    kickGain.connect(this.audioCtx!.destination);
    kickGain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx!.currentTime + 0.5);

    const oscillator = this.audioCtx!.createOscillator();
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(150, this.audioCtx!.currentTime);
    oscillator.connect(kickGain)
    oscillator.frequency.exponentialRampToValueAtTime(0.01, this.audioCtx!.currentTime + 0.5);

    oscillator.start(this.currentChord * this.bpm / 1000);
    oscillator.stop((this.currentChord * this.bpm / 1000) + 0.2);
  }

  private playSnare() {
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
    source.start(this.currentChord * this.bpm / 1000);
  }

  private playHihat() {
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
    source.start(this.currentChord * this.bpm / 1000);
  }

  private invokeInterval() {
    const lookahead = 75;
    const interval = 50;

    while (this.playing && this.currentChord * this.bpm < (this.audioCtx!.currentTime * 1000) + lookahead) {
      let chord: number[] = this.state.melody[this.currentChord % 8];
      chord.forEach((frequency) => {
        const gainNode = this.audioCtx!.createGain();
        const startTime = this.currentChord * this.bpm / 1000;
        gainNode.gain.setValueAtTime(0, startTime);
        gainNode.gain.linearRampToValueAtTime(0.8, startTime + this.state.envelope.attack);
        gainNode.gain.linearRampToValueAtTime(this.state.envelope.sustain * 0.8, startTime + this.state.envelope.attack + this.state.envelope.decay);
        gainNode.gain.setValueAtTime(this.state.envelope.sustain * 0.8, startTime + 0.2 - this.state.envelope.release);
        gainNode.gain.linearRampToValueAtTime(0, startTime + 0.2);
        gainNode.connect(this.audioCtx!.destination);

        const oscillator = this.audioCtx!.createOscillator();
        oscillator.type = this.wave;
        oscillator.frequency.setValueAtTime(frequency * 2 ** this.octave, this.audioCtx!.currentTime);

        // Create delay node

        // Create feedback gain node
        if (this.state.delay.feedback > 0) {
          console.log("feedback is: " + this.state.delay.feedback);
          const delayNode = this.audioCtx!.createDelay(1.0); // Maximum delay of 5 seconds
          delayNode.delayTime.setValueAtTime(this.state.delay.time, this.audioCtx!.currentTime); // 300ms delay
          const feedbackGain = this.audioCtx!.createGain();
          feedbackGain.gain.setValueAtTime(this.state.delay.feedback, this.audioCtx!.currentTime); // 40% feedback
          delayNode.connect(feedbackGain);
          feedbackGain.connect(delayNode);
          gainNode.connect(delayNode);
          delayNode.connect(this.audioCtx!.destination);
        }

        // Connect nodes: oscillator -> gain -> delay -> destination
        oscillator.connect(gainNode);

        // Create feedback loop

        const lfo = this.audioCtx!.createOscillator();
        lfo.type = 'sine';
        lfo.frequency.setValueAtTime(this.lfoFrequency, this.audioCtx!.currentTime);

        const lfoGain = this.audioCtx!.createGain();
        lfoGain.gain.setValueAtTime(this.lfoIntensity, this.audioCtx!.currentTime);

        lfo.connect(lfoGain);
        lfoGain.connect(oscillator.frequency);

        oscillator.start(this.currentChord * this.bpm / 1000);
        oscillator.stop((this.currentChord * this.bpm / 1000) + 0.2);
        // oscillator.stop((this.currentChord * this.bpm / 1000) + 1);
        lfo.start();
      })

      if (this.drumPatterns.get("kick")![this.currentChord % 16]) {
        this.playKick();
      }

      if (this.drumPatterns.get("snare")![this.currentChord % 16]) {
        this.playSnare();
      }

      if (this.drumPatterns.get("hihat")![this.currentChord % 16]) {
        this.playHihat();
      }

      this.viewUpdateCallback(this.currentChord);
      this.currentChord += 1;
    }

    if (this.playing) {
      this.intervalIds.push(setTimeout(() => { this.invokeInterval() }, interval));
    }
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

      this.playing = true;
      this.invokeInterval();
    } else if (audioCommand === "pause") {
      this.playing = false;
      this.clearIntervals();
    } else if (audioCommand === "reset") {
      this.playing = false;
      this.clearIntervals();
      this.currentChord = 0;

      this.audioCtx!.close();
      this.audioCtx! = new AudioContext();
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
      default:
        console.warn(`Unknown message tag: ${tag}`);
    }
  }

  public toggleDrumPatternAt(drum: string, column: number) {
    this.drumPatterns.get(drum)![column] = !this.drumPatterns.get(drum)![column];
  }

  public updateWave(wave: string) {
    this.wave = wave.toLowerCase();
  }

  public updateBpm(bpm: number) {
    this.bpm = bpm;
  }

  public updateLfoFrequency(freq: number) {
    this.lfoFrequency = freq;
  }

  public updateLfoIntensity(intensity: number) {
    this.lfoIntensity = intensity;
  }

  public updateOctave(octave: number) {
    this.octave = octave;
  }
}