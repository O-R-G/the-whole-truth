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
int bands = 128;            // FFT bands to use (must be a power of two)
int scale = 5;              // [5]
float smoothingFactor = 0.2;
float[] sum = new float[bands]; // smoothed spectrum data
float barWidth;

public void setup() {
    size(360, 640);
    // size(720, 1280);
    // size(1080, 1920);
    background(0);
    noStroke();

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

        if (current_time >= verdicts[pointer].in) {
            background(0);
            fft.analyze();
            for (int i = 0; i < bands; i++) {
                // adjust color between r and b
                // fill(i*2,0,((bands-i)*2)-1);

                // Smooth the FFT spectrum data by smoothing factor
                sum[i] += (fft.spectrum[i] - sum[i]) * smoothingFactor;

                // Draw the rectangles, adjust their height using the scale factor
                rect(i*barWidth, height, barWidth, -sum[i]*height*scale);

                // gradient(int(i*barWidth), int(height), barWidth, -sum[i]*height*scale,color(255,0,0),color(0,0,255));
                // gradient(int(i*barWidth), int(height), barWidth * 1.5, 100.0, color(255,0,0), color(0,0,255));
            }
int i = 2;
println(barWidth);
println(sum[i]*height);
            gradient(i*barWidth, 0, height/2, sum[i]*height*scale, color(255,0,0), color(0,0,255));
            // gradient(0,0,width/32, height, color(255,0,0),color(0,0,255));                
            pointer++;
        }
    }

    show_current_millis();
}

private void show_current_millis() {
    fill(255);
    text(millis(),width-100,24);
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

void gradient(int x, int y, float w, float h, color c1, color c2) {
    noFill();
    for (int i = y; i <= y+h; i++) {
        float inter = map(i, y, y+h, 0, 1);
        color c = lerpColor(c1, c2, inter);
        stroke(c);
        line(x, i, x+w, i);
    }
}


