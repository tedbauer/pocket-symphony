const chordTimeMs = 250;
var currentChord = 0;
var audioCtx: AudioContext;
var melody: number[][];
var viewUpdateCallback: Function;

function invokeInterval() {
  const lookahead = 75;
  const interval = 50;

  while (currentChord * chordTimeMs < (audioCtx.currentTime * 1000) + lookahead) {
    let chord: number[] = melody[currentChord % 8];
    chord.forEach((frequency) => {
      const gainNode = audioCtx.createGain();
      gainNode.gain.setValueAtTime(0.8, audioCtx.currentTime);  // Set initial gain
      gainNode.connect(audioCtx.destination);
      
      const oscillator = audioCtx.createOscillator();
      oscillator.type = "sine";
      oscillator.frequency.setValueAtTime(frequency, audioCtx.currentTime);
      oscillator.connect(gainNode);

      oscillator.start(currentChord * chordTimeMs / 1000);
      oscillator.stop((currentChord * chordTimeMs / 1000) + 0.2);
    })

    viewUpdateCallback(currentChord % 8);
    currentChord += 1;
  }

  setTimeout(invokeInterval, interval)
}

export class AudioPlayer {
  private viewUpdateCallback: Function;
  private melody: number[];

  constructor(viewUpdateCallback2: Function) {
    this.viewUpdateCallback = viewUpdateCallback;
    this.melody = [];

    viewUpdateCallback = viewUpdateCallback2;
  }

  public processCommand(command: number[][]) {
    audioCtx = new AudioContext();
    melody = command;

    invokeInterval();
  }

  public setMelody(command: number[][]) {
    console.log(command);
    melody = command;
  }

  public setPlaying(playing: boolean) {
  }
}