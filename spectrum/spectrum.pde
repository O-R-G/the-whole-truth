/*
    spectrum

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

import processing.sound.*;

SoundFile sample;
FFT fft;
PFont mono;
Table table;
StringDict colors;
Verdict[] verdicts;

int millis_start = 0;       // when audio starts playing (millis)
int current_time = 0;       // position in soundfile (millis)
int pointer;                // current index in verdicts[]
int counter;                // draw loop
int display_scale = 1;
Boolean playing = false;
String data_path = "/Users/reinfurt/Documents/Softwares/Processing/the_whole_truth/data/";

int samples = 100;          // samples of waveform to read at once
// int bands = 128;         // FFT bands to use (must be a power of 2)
int bands = 256;            // FFT bands to use (must be a power of 2)
int crop = 4;               // horizontal crop of frequencies (must be a power of 2)
int scale = 20;              // [5]
int capture_delay = 300;    // delay before captures FFT so gets a broader spectrum
                            // would be better to average over a longer time
float smoothingFactor = 0.2;
float[] sum = new float[bands]; // smoothed spectrum data
float barWidth;

public void setup() {
    size(360, 640);
    // size(720, 1280);
    // size(1080, 1920);
    background(0);
    noStroke();
    rectMode(CORNERS);              // specify 4 corners (x1,y1,x2,y2) not (x,y,w,h)
    colorMode(HSB);

    /*
    Sound.list();                   // sound output devices to stdout
    Sound s = new Sound(this);      // need sound object to set device
    s.outputDevice(2);              // set to built-in output for muting as needed
    */

    set_colors();
    load_csv();
    counter = 0;
    pointer = 0;

    sample = new SoundFile(this, data_path + "the-whole-truth.wav");
    sync_sample();
    // play_sample();

    barWidth = width/float(bands);
    // barWidth *= 4;                  // wider bars, crops frequencies display 
    fft = new FFT(this, bands);
    fft.input(sample);

    mono = createFont("fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
}

public void draw() {

    if (playing) {
        current_time = millis() - millis_start;
        // draw_grid();

        if (current_time >= verdicts[pointer].in + capture_delay) {
            background(0);

            fft.analyze();
            for (int i = 0; i < bands / crop; i++) {
                // adjust color between r & b
                // fill(i*2,0,((bands-i)*2)-1);

                // smooth FFT data over a time window
                sum[i] += (fft.spectrum[i] - sum[i]) * smoothingFactor;

                // using rectMode(CORNERS) instead of default rectMode(CORNER)
                // specify 4 corners (x1,y1,x2,y2) not (x,y,w,h)
                // rect(i*barWidth*crop, height, i*barWidth*crop+barWidth, height-sum[i]*height*scale);
                // gradient(int(i*barWidth*crop), int(height), int(i*barWidth*crop+barWidth), int(height-sum[i]*height*scale),color(0,255,255),color(255,255,255));
                gradient(int(i*barWidth*crop), int(height), int(i*barWidth*crop+barWidth), int(height-sum[i]*height*scale),0,255);
            }
            fill(0,0,0);
            noStroke();
            rect(width-100, 36, width, 30);
            show_capture_time(width-70, 44);
            pointer++;
        }
    }

    // update current_time display
    fill(0,0,0);
    noStroke();
    rect(width-100, 0, width, 30);
    show_current_time(width-70, 24);
}

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

/*

    gradient

*/

void gradient(int x1, int y1, int x2, int y2, int h1, int h2) {

    // rewritten for rectMode(CORNERS)
    // better with floats?
    // assumes colorMode(USB)
    // using h,s,b where only h matters
    // so lerp between hue values

    noFill();
    for (int i = y1; i >= y2; i--) {
        float inter = map(i, height, 0, 0, 1);
        float hue = lerp(h1, h2, inter);
        // color c = lerpColor(c1, c2, inter);
        color c = color(hue, 255, 255);
        stroke(c);
        line(x1, i, x2, i);
    }
}

void draw_grid() {
    int incr = int(height/10);
    for (int i = 0; i < height; i+=incr) {
        stroke(0,0,50);
        line(0, i, width, i);
    }
}
