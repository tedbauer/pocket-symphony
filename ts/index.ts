export class AudioPlayer {
  private viewUpdateCallback: Function;
  private audioCtx: AudioContext;

  private melody: number[][];
  private bpm: number;
  private currentChord;
  private playing: boolean;

  private intervalIds: any[];

  constructor(viewUpdateCallback: Function) {
    this.viewUpdateCallback = viewUpdateCallback;

    this.melody = [];
    this.currentChord = 0;
    this.playing = false;
    this.bpm = 500;

    this.intervalIds = [];
    this.audioCtx = new AudioContext();
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
        oscillator.type = "sine";
        oscillator.frequency.setValueAtTime(frequency, this.audioCtx.currentTime);
        oscillator.connect(gainNode);

        oscillator.start(this.currentChord * this.bpm / 1000);
        oscillator.stop((this.currentChord * this.bpm / 1000) + 0.2);
      })

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

  public updateBpm(bpm: number) {
    this.bpm = bpm;
  }
}