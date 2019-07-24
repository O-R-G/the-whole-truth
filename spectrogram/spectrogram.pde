/*
    spectrogram

    analyzes a stream of sound using a Fast Fourier Transform
    to unpack constituent frequencies displayed as amplitudes
    changing over time. number of FFT bands can be adjusted 
    for finer/coarser resolution.

    based on FFTSpectrum example in processing.sound        
    uses processing.sound for FFT analysis
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
int column;

public void setup() {
    size(360, 640, FX2D);
    background(0);
    noStroke();
    // colorMode(HSB);
    colorMode(HSB,255);
    // colorMode(HSB,360,255,255);

    sgram = new int[rows][columns];

    set_colors();
    load_csv();
    counter = 0;
    pointer = 0;

    minim = new Minim(this);
    sample = minim.loadFile(data_path + "the-whole-truth.wav", bufferSize);
    fft = new FFT(sample.bufferSize(), sampleRate);
    fft.window(FFT.HAMMING);      // tapered time window avoids 'splatter'
    sample.play();

    mono = createFont(data_path + "fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
}

public void draw() {
    background(0);
      
    // continuous

    fft.forward(sample.mix);    
    update_spectrogram();
    // if (counter % 300 < 50)
        draw_spectrogram();
    // draw_axis();
    counter++;

    /*
    // snapshot

    if (playing) {
        current_time = millis() - millis_start;
        // draw_grid();

        if (current_time >= verdicts[pointer].in + capture_delay) {
            background(0);
            show_capture_time(width-70, 44);
            pointer++;
        }
    }
    */

    show_current_time(width-70, 24);
}

/*

    display time

*/

private void show_current_millis() {
    fill(255);
    text(millis(),width-100,24);
}

private void show_current_time(int x, int y) {
    int seconds_total = millis() / 1000;
    int minutes = floor(seconds_total / 60);
    int seconds = seconds_total % 60;
    String sec = nf(seconds, 2);
    String min = nf(minutes, 2);
    fill(255/3,255,255);
    text(min + ":" + sec,x,y);
}

private void show_capture_time(int x, int y) {
    int seconds_total = millis() / 1000;
    int minutes = floor(seconds_total / 60);
    int seconds = seconds_total % 60;
    String sec = nf(seconds, 2);
    String min = nf(minutes, 2);
    fill(0,0,255);
    text(min + ":" + sec,x,y);
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
            // stroke(sgram[j][i+column],255,255);
            stroke(rotate_hue(sgram[j][i+column],90.0),255,255);
            point(i,height-j);
        }
    }
    for (int i = 0; i < column; i++) {
        for (int j = 0; j < rows; j++) {
            // stroke(sgram[j][i],255,255);
            stroke(rotate_hue(sgram[j][i],90.0),255,255);
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

/*
Boolean play_sample() {
    if (!playing) {
        millis_start = millis();
        sample.loop();
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
*/

void exit() {
    stop();
}

void stop() {
    // always dispose minim object
    sample.pause();
    minim.stop();
    super.stop();
}

