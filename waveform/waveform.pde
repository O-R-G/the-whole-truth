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

int millis_start = 0;       // when audio starts playing (millis)
int current_time = 0;       // position in soundfile (millis)
int pointer;                // current index in verdicts[]
int counter;                // draw loop
int samples = 100;          // samples of waveform to read at once
int display_scale = 1;      // adjust to match size() 
Boolean playing = false;
String data_path = "/Users/reinfurt/Documents/Softwares/Processing/the_whole_truth/data/";
Boolean debug = true;       // display time debug
Boolean mute = false;       // no sound
Boolean sync = true;        // start audio w/sync_sample()

public void setup() {
    size(640, 360);
    // size(1280, 720);
    // size(1920, 1080);
    background(255);

    sample = new SoundFile(this, data_path + "the-whole-truth.wav");
    waveform = new Waveform(this, samples);
    waveform.input(sample);
    if (sync)
        sync_sample();
    else
        play_sample();

    mono = createFont(data_path + "fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
}

public void draw() {
    background(0);
    stroke(0, 255, 0);
    strokeWeight(2);
    noFill();

    if (playing) {
        current_time = millis() - millis_start;
        waveform.analyze();
        beginShape();
        for(int i = 0; i < samples; i++){
            vertex(
                map(i, 0, samples, 0, width),
                map(waveform.data[i], -1, 1, 0, height)
            );
        }
        endShape();
        if (debug)
            show_current_time(width-70, 24);
    }
}

/*

    display time

*/

private void show_current_millis() {
    fill(255);
    text(millis(),width-100,24);
}

private void show_current_time(int x, int y) {
    fill(0);
    noStroke();
    rect(x-24,y-24,100,30);
    fill(255/3,255,255);
    text(get_time(current_time),x,y);
}

private void show_capture_time(int x, int y) {
    fill(0,0,255);
    text(get_time(current_time),x,y);
}

private String get_time(int current_time) {
    int seconds = (current_time / 1000) % 60;
    int minutes = (current_time / (1000 * 60)) % 60;
    return nf(minutes, 2) + ":" + nf(seconds, 2);
}

/*
private void timing_debug(int x, int y) {
    text(verdicts[pointer].txt,x,y);
    saveFrame("out/debug-######.tif");
}
*/

/*

    sound control

*/

Boolean play_sample() {
    if (!playing) {
        millis_start = millis();
        sample.loop();
        if (mute)
            sample.amp(0.0);
        else   
            sample.amp(1.0);
        playing = true;
        return true;
    } else {
        return false;
    }
}

Boolean stop_sample() {
    playing = false;
    sample.stop();
    return true;
}

Boolean sync_sample() {
    while (second() % 10 !=0) {  
        println(second() % 10);
    }
    play_sample();
    // sample.amp(0.0);
    if (playing)
        return true;
    else
        return false;
}
