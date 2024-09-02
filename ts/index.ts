export class AudioPlayer {
  private viewUpdateCallback: Function;
  private audioCtx?: AudioContext;

  private melody: number[][];
  private bpm: number;
  private currentChord;
  private playing: boolean;

  private drumPatterns: Map<string, boolean[]>

  private intervalIds: any[];

  private wave: any = "sine";

  private lfoFrequency: number;
  private lfoIntensity: number;

  private octave: number;

  private attack: number;
  private release: number;
  private sustain: number;
  private decay: number;

  constructor(viewUpdateCallback: Function) {
    this.viewUpdateCallback = viewUpdateCallback;

    this.melody = [[], [], [], [], [], [], [], []];
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

    this.attack = 0;
    this.decay = 0.1;
    this.sustain = 0.02;
    this.release = 0.001;
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
      let chord: number[] = this.melody[this.currentChord % 8];
      chord.forEach((frequency) => {
        const gainNode = this.audioCtx!.createGain();
        const startTime = this.currentChord * this.bpm / 1000;
        gainNode.gain.setValueAtTime(0, startTime);
        gainNode.gain.linearRampToValueAtTime(0.8, startTime + this.attack); // Attack
        gainNode.gain.linearRampToValueAtTime(this.sustain * 0.8, startTime + this.attack + this.decay); // Decay to Sustain
        gainNode.gain.setValueAtTime(this.sustain * 0.8, startTime + 0.2 - this.release); // Sustain
        gainNode.gain.linearRampToValueAtTime(0, startTime + 0.2); // Release
        gainNode.connect(this.audioCtx!.destination);

        const oscillator = this.audioCtx!.createOscillator();
        oscillator.type = this.wave;
        oscillator.frequency.setValueAtTime(frequency * 2 ** this.octave, this.audioCtx!.currentTime);

        // Create delay node
        const delayNode = this.audioCtx!.createDelay(1.0); // Maximum delay of 5 seconds
        delayNode.delayTime.setValueAtTime(0.9, this.audioCtx!.currentTime); // 300ms delay

        // Create feedback gain node
        const feedbackGain = this.audioCtx!.createGain();
        feedbackGain.gain.setValueAtTime(0.4, this.audioCtx!.currentTime); // 40% feedback

        // Connect nodes: oscillator -> gain -> delay -> destination
        oscillator.connect(gainNode);
        gainNode.connect(delayNode);
        delayNode.connect(this.audioCtx!.destination);

        // Create feedback loop
        delayNode.connect(feedbackGain);
        feedbackGain.connect(delayNode);

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

  public updateMelody(melody: number[][]) {
    this.melody = melody;
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

  public updateAttack(attack: number) {
    this.attack = attack;
    console.log("attack is set to " + this.attack)
  }

  public updateRelease(release: number) {
    this.release = release;
  }

  public updateSustain(sustain: number) {
    this.sustain = sustain;
  }

  public updateDecay(decay: number) {
    this.decay = decay;
  }
}