/**
 * waveform
 *
 * analyzes a stream of raw sound to plot waveform
 * as continuous set of amplitude values {-1,1} over time.
 * time displayed can be adjusted.
 *
 * based on AudioWaveform example in processing.sound
 * uses processing.sound for Amplitude analysis
 * uses processing.sound for Waveform analysis
 * uses Speech-to-text-normal
 *
 * O-R-G
 * for Lawrence Abu Hamdan, The Whole Truth
 */

import processing.sound.*;

SoundFile sample;
Waveform waveform;
PFont mono;

// Define how many samples of the Waveform to read at once
int samples = 100;

public void setup() {
    size(640, 360);
    background(255);

    // sample = new SoundFile(this, "the-whole-truth-90-seconds.wav");
    sample = new SoundFile(this, "the-whole-truth.wav");
    while (second() % 5 !=0) {
        // wait so that all three apps start audio at same time 
    }
    sample.play();

    waveform = new Waveform(this, samples);
    waveform.input(sample);

    mono = createFont("fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
}

public void draw() {
    background(0);
    stroke(0, 255, 0);
    strokeWeight(2);
    noFill();

    waveform.analyze();
  
    beginShape();
    for(int i = 0; i < samples; i++){
        // Draw current data of the waveform
        // Each sample in the data array is between -1 and +1 
        vertex(
            map(i, 0, samples, 0, width),
            map(waveform.data[i], -1, 1, 0, height)
        );
    }
    endShape();
    show_current_time();
}

private void show_current_time() {
    int seconds = millis() / 1000;
    int minutes = seconds / 60;
    String sec = nf(seconds, 2);
    String min = nf(minutes, 2);
    fill(255);
    text(min + ":" + sec,width-100,24);
}

