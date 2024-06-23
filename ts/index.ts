export class AudioPlayer {
  private viewUpdateCallback: Function;
  private audioCtx: AudioContext;

  private melody: number[][];
  private bpm: number;
  private currentChord;
  private playing: boolean;

  private drumPatterns: Map<string, boolean[]>

  private intervalIds: any[];

  private wave: any = "sine";

  constructor(viewUpdateCallback: Function) {
    this.viewUpdateCallback = viewUpdateCallback;

    this.melody = [];
    this.currentChord = 0;
    this.playing = false;
    this.bpm = 500;

    this.drumPatterns = new Map([
      ["kick", Array(16).fill(false)],
      ["hihat", Array(16).fill(false)],
      ["snare", Array(16).fill(false)],
    ]);

    this.intervalIds = [];
    this.audioCtx = new AudioContext();
  }

  private playKick() {
    const kickGain = this.audioCtx.createGain();
    kickGain.gain.setValueAtTime(1, this.audioCtx.currentTime);
    kickGain.connect(this.audioCtx.destination);
    kickGain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx.currentTime + 0.5);

    const oscillator = this.audioCtx.createOscillator();
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(150, this.audioCtx.currentTime);
    oscillator.connect(kickGain)
    oscillator.frequency.exponentialRampToValueAtTime(0.01, this.audioCtx.currentTime + 0.5);

    oscillator.start(this.currentChord * this.bpm / 1000);
    oscillator.stop((this.currentChord * this.bpm / 1000) + 0.2);
  }

  private playSnare() {
    const bufferSize = this.audioCtx.sampleRate * 0.2;
    const buffer = this.audioCtx.createBuffer(1, bufferSize, this.audioCtx.sampleRate);
    const output = buffer.getChannelData(0);

    for (let i = 0; i < bufferSize; i++) {
        output[i] = Math.random() * 2 - 1;
    }

    const source = this.audioCtx.createBufferSource();
    source.buffer = buffer;

    const snareGain = this.audioCtx.createGain();
    snareGain.gain.setValueAtTime(1, this.audioCtx.currentTime);
    snareGain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx.currentTime + 0.2);

    source.connect(snareGain);
    snareGain.connect(this.audioCtx.destination);
    source.start(this.currentChord * this.bpm / 1000);
  }

  private playHihat() {
    const bufferSize = this.audioCtx.sampleRate * 0.1;
    const buffer = this.audioCtx.createBuffer(1, bufferSize, this.audioCtx.sampleRate);
    const output = buffer.getChannelData(0);

    for (let i = 0; i < bufferSize; i++) {
        output[i] = Math.random() * 2 - 1;
    }

    const source = this.audioCtx.createBufferSource();
    source.buffer = buffer;

    const hihatGain = this.audioCtx.createGain();
    hihatGain.gain.setValueAtTime(1, this.audioCtx.currentTime);
    hihatGain.gain.exponentialRampToValueAtTime(0.01, this.audioCtx.currentTime + 0.1);

    source.connect(hihatGain);
    hihatGain.connect(this.audioCtx.destination);
    source.start(this.currentChord * this.bpm / 1000);
  }

  private invokeInterval() {
    const lookahead = 75;
    const interval = 50;

    while (this.playing && this.currentChord * this.bpm < (this.audioCtx.currentTime * 1000) + lookahead) {
      let chord: number[] = this.melody[this.currentChord % 8];
      chord.forEach((frequency) => {
        const gainNode = this.audioCtx.createGain();
        gainNode.gain.setValueAtTime(0.8, this.audioCtx.currentTime);
        gainNode.connect(this.audioCtx.destination);

        const oscillator = this.audioCtx.createOscillator();
        oscillator.type = this.wave;
        oscillator.frequency.setValueAtTime(frequency, this.audioCtx.currentTime);
        oscillator.connect(gainNode);

        oscillator.start(this.currentChord * this.bpm / 1000);
        oscillator.stop((this.currentChord * this.bpm / 1000) + 0.2);
      })

      if (this.drumPatterns.get("kick")![this.currentChord % 8]) {
        this.playKick();
      }

      if (this.drumPatterns.get("snare")![this.currentChord % 8]) {
        this.playSnare();
      }

      if (this.drumPatterns.get("hihat")![this.currentChord % 8]) {
        this.playHihat();
      }

      this.viewUpdateCallback(this.currentChord % 8);
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
      this.playing = true;
      this.invokeInterval();
    } else if (audioCommand === "pause") {
      this.playing = false;
      this.clearIntervals();
    } else if (audioCommand === "reset") {
      this.playing = false;
      this.clearIntervals();
      this.currentChord = 0;

      this.audioCtx.close();
      this.audioCtx = new AudioContext();
    }
  }

  public updateMelody(melody: number[][]) {
    this.melody = melody;
  }

  public toggleDrumPatternAt(drum: string, column: number) {
    console.log(drum);
    this.drumPatterns.get(drum)![column] = !this.drumPatterns.get(drum)![column];
  }

  public updateWave(wave: string) {
    this.wave = wave.toLowerCase();
  }

  public updateBpm(bpm: number) {
    this.bpm = bpm;
  }
}