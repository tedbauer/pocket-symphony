const CHORD_TIME_MS = 250;

export class AudioPlayer {
  private viewUpdateCallback: Function;
  private audioCtx: AudioContext;

  private melody: number[][];
  private currentChord;
  private playing: boolean;

  private intervalIds: any[];

  constructor(viewUpdateCallback: Function) {
    this.viewUpdateCallback = viewUpdateCallback;
    this.audioCtx = new AudioContext();

    this.melody = [];
    this.currentChord = 0;
    this.playing = false;

    this.intervalIds = [];
  }

  private invokeInterval() {
    const lookahead = 75;
    const interval = 50;

    while (this.playing && this.currentChord * CHORD_TIME_MS < (this.audioCtx.currentTime * 1000) + lookahead) {
      let chord: number[] = this.melody[this.currentChord % 8];
      chord.forEach((frequency) => {
        const gainNode = this.audioCtx.createGain();
        gainNode.gain.setValueAtTime(0.8, this.audioCtx.currentTime);
        gainNode.connect(this.audioCtx.destination);

        const oscillator = this.audioCtx.createOscillator();
        oscillator.type = "sine";
        oscillator.frequency.setValueAtTime(frequency, this.audioCtx.currentTime);
        oscillator.connect(gainNode);

        oscillator.start(this.currentChord * CHORD_TIME_MS / 1000);
        oscillator.stop((this.currentChord * CHORD_TIME_MS / 1000) + 0.2);
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
      console.log(this.currentChord % 8);
      this.playing = true;
      this.invokeInterval();
    } else if (audioCommand === "pause") {
      console.log(this.currentChord % 8);
      this.playing = false;
      this.clearIntervals();
    }
  }

  public updateMelody(melody: number[][]) {
    this.melody = melody;
  }
}