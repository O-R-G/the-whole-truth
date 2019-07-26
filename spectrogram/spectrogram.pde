/*
    spectrogram

    analyzes a stream of sound using a Fast Fourier Transform
    to unpack constituent frequencies displayed as amplitudes
    changing over time. number of FFT bands can be adjusted 
    for finer/coarser resolution. the series of FFT are then
    rotated -90 degrees around z and 90 degrees around y to make 
    a 3-dimensional heat map of the changing FFT snapshots
    over time, with amplitude indicated by color.

    based on LiveSpectrogram, Dan Ellis dpwe@ee.columbia.edu 
    uses minim sound library for playback and analysis 
    uses Speech-to-text-normal

    O-R-G
    for Lawrence Abu Hamdan, The Whole Truth
*/

import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;
AudioInput in;
AudioPlayer sample;
FFT fft;
PFont mono;

Table table;
StringDict colors;
Verdict[] verdicts;

int millis_start = 0;       // when audio starts playing (millis)
int current_time = 0;       // position in soundfile (millis)
int pointer;                // current index in verdicts[]
int counter;                // draw loop
int display_scale = 2;      // adjust to match size() 
Boolean playing = false;
String data_path = "/Users/reinfurt/Documents/Softwares/Processing/the_whole_truth/data/";

int[][] sgram;              // all spectrogram data
int columns = 360;          // spectrogram width in pixels
int rows = 640;             // spectrogram height in pixels
                            // also the number of bands in FFT
float sampleRate = 48000;   // from the audio file
int bufferSize = 1024;      // must be a power of 2 [512,1024,2048]
int column;                 // current x position in spectrogram
int freeze_time = 0;        // current_time when freeze started
Boolean snap_shots = true;  // show only timed stills, otherwise scrolling
Boolean debug = true;       // display time debug
Boolean mute = true;       // no sound
Boolean sync = true;       // start audio w/sync_sample()

public void setup() {
    size(360, 640, FX2D);
    background(0);
    noStroke();
    colorMode(HSB);

    sgram = new int[rows][columns];

    set_colors();
    load_csv();
    counter = 0;
    pointer = 0;

    minim = new Minim(this);
    sample = minim.loadFile(data_path + "the-whole-truth.wav", bufferSize);
    fft = new FFT(sample.bufferSize(), sampleRate);
    fft.window(FFT.HAMMING);    // tapered time window avoids 'splatter'
    if (sync) 
        sync_sample();
    else 
        play_sample();

    mono = createFont(data_path + "fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
}

public void draw() {

    fft.forward(sample.mix);    
    update_spectrogram();
    if (playing) {
        current_time = millis() - millis_start;
        freeze_fade();
        if (debug)
            show_current_time(width-70, 24);
    }
    counter++;
}

public void freeze_fade() {
   
    // globals current_time, freeze_time
    
    int fade_duration = 1000;       // duration in millis
    int freeze_duration = 3000;     // duration in millis
        
    if (current_time >= verdicts[pointer].in) {
        background(0);
        draw_spectrogram();
        show_capture_time(width-70, 44);
        timing_debug(10, 44);
        freeze_time = current_time;
        pointer++;
    }
    if ((current_time >= freeze_time + freeze_duration) &&
        (current_time <= freeze_time + freeze_duration + fade_duration)) {
        noStroke();
        fill(0,20);
        rect(0,0,width,height);
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

private void timing_debug(int x, int y) {
    text(verdicts[pointer].txt,x,y);
    saveFrame("out/debug-######.tif"); 
}

/* 

    spectrogram

*/

Boolean update_spectrogram() {

    /*
        updates sgram[][] ring-filled array, updates one column at a time
        get magnitude for each each frequency band in FFT
        then 2*20*Math.log10(1000*fft.getBand(i))) to convert magnitude -> decibels
        (magnitude is distance from 0 in either direction,
        amplitude includes direction, so can be positive or negative)
        updates one column (all rows) because spectrogram is like
        spectrum rotated 90 degrees counterclockwise and then 90 degrees in z
        fft.specSize() returns number of bands (same as rows)

        waveform (amp/time)
            _
        _  / \__
         \/

        spectrum (amp/freq)

        .| .|
        ||.|||..

        spectrogram (amp/freq/time)

        .*+-**-.
        --.+.-+.
        ..x.**.+
        .+....-.
    */

    for (int i = 0; i < rows; i++)
        sgram[i][column] = (int)Math.round(Math.max(0,2*20*Math.log10(1000*fft.getBand(i))));
    column++;
    if (column == columns)
        column = 0;
        
    return true;
}

Boolean draw_spectrogram() {

    // draw sgram[column][] to sgram[columns][]
    // then draw sgram[0][] to sgram[column][]

    for (int i = 0; i < columns-column; i++) {
        for (int j = 0; j < rows; j++) {
            stroke(rotate_hue_with_filter(sgram[j][i+column],90.0));
            point(i,height-j);
        }
    }
    for (int i = 0; i < column; i++) {
        for (int j = 0; j < rows; j++) {
            stroke(rotate_hue_with_filter(sgram[j][i],90.0));
            point(i+columns-column,height-j);
        }
    }
    return true;
}

float rotate_hue(float hue, float degrees) {

    // hue {0-255}, degrees {0-360}
    // remap degrees, hue
    // then subtract degrees_mapped from hue_mapped % 255
    // (+ 255 for negative values wrapping around 0)
    // assumes counterclockwise rotation

    float hue_mapped = map(hue, 0, 255, 0, 127);
    float degrees_mapped = map(degrees, 0, 360, 0, 255);
    hue = (hue_mapped - degrees_mapped + 255) % 255;

    return hue;
}

color rotate_hue_with_filter(float hue, float degrees) {

    // hue {0-255}, degrees {0-360}
    // remap to 0-255, then subtract degrees_mapped from hue_mapped % 255
    // + 255 for negative values wrapping around 0
    // assumes counterclockwise rotation
    // hi-pass, lo-pass filter mimics spectrogram gradients
    // add black when low, add white when high
    // k = color(h,255,0)
    // w = color(h,0,255)

    float brightness = 255;
    float saturation = 255;
    if (hue < 20)
        brightness = map(hue, 0, 20, 0, 255);
    if (hue > 245)
        saturation = map(hue, 245, 255, 0, 255);

    // float hue_mapped = map(hue, 0, 255, 0, 127);
    float hue_mapped = map(hue, 0, 255, 0, 255);
    float degrees_mapped = map(degrees, 0, 360, 0, 255);
    hue = (hue_mapped - degrees_mapped + 255) % 255;

    return color(hue, saturation, brightness);
}

void draw_axis() {

    int x = columns + 2;     // to right of spectrogram display
    stroke(255);
    line(x,0,x,height);     // vertical line
    textAlign(LEFT,CENTER);
    for (float freq = 0.0; freq < in.sampleRate()/2; freq += 500.0) {
        int y = height - fft.freqToIndex(freq); // which bin holds this frequency
        line(x,y,x+3,y);    // tick mark
        text(Math.round(freq)+" Hz", x+5, y); // add text label
    }
}

void draw_grid() {
    int incr = int(height/10);
    for (int i = 0; i < height; i+=incr) {
        stroke(0,0,50);
        line(0, i, width, i);
    }
}

/*

    objects from .csv data

*/

void load_csv() {
    table = loadTable(data_path + "verdicts.csv", "header");
    verdicts = new Verdict[table.getRowCount()];

    for (int i = 0; i < table.getRowCount(); i++) {
        TableRow row = table.getRow(i);
        int m = row.getInt("m");
        int s = row.getInt("s");
        int frame = row.getInt("frame");
        float f = float(frame)/30;
        int in = round((m * 60 + s + f) * 1000);
        int out = in + 1000;
        String txt = row.getString("VERDICT");
        String c_str = colors.get(txt);
        int[] c_ = int(split(c_str,","));
        color c = color(c_[0], c_[1], c_[2]);
        if (c_str == null) {
            println(txt + ", " + c_str);
            c = color(192,192,192);
        }
        verdicts[i] = new Verdict(in,out,txt,c);

        println(verdicts[i].in + ":" + verdicts[i].out + " " + verdicts[i].txt);
    }
    println(verdicts.length + " rows");
}

Boolean set_colors() {
    // match .csv rows based on verdict txt
    colors = new StringDict();
    colors.set("TRUTH", "255,255,255");
    colors.set("SUBJECT EMPHATIC", "247,203,202");
    colors.set("SUBJECT MANIPULATING VOICE", "235,85,248");
    colors.set("AVOIDANCE", "140,140,140");
    colors.set("SUBJECT ATTEMPTING OUTSMART", "150,50,200");
    colors.set("SUBJECT IS NOT SURE", "255,253,205");
    colors.set("INACCURACY", "140,136,39");
    colors.set("LIE", "0,0,0");
    return true;
}

/*

    sound control

*/

Boolean play_sample() {
    if (!playing) {
        millis_start = millis();
        sample.play();
        if (mute)
            sample.mute();
        else
            sample.unmute();
        playing = true;
        return true;
    } else {
        return false;
    }
}

Boolean pause_sample() {
    playing = false;
    sample.pause();
    return true;
}

Boolean sync_sample() {
    while (second() % 10 !=0) {
        println(second() % 10);
    }
    play_sample();
    if (playing)
        return true;
    else
        return false;
}

void exit() {
    stop();
}

void stop() {
    // always dispose minim object
    sample.pause();
    minim.stop();
    super.stop();
}
